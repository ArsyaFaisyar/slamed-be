from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session

from pydantic import BaseModel, Field
from app.db.database import get_db
from app.models.customer import Customer
from app.models.user import User
from app.models.area import Area
from app.schemas.customer import (
    CustomerCreate,
    CustomerUpdate,
    CustomerResponse,
)
from app.core.dependencies import get_current_user, require_roles
from app.core.roles import CUSTOMER_VIEW_ROLES
from datetime import datetime, timezone

router = APIRouter(
    prefix="/customers",
    tags=["Customers"],
)


def validate_area(db: Session, area_id: int | None):
    if area_id is None:
        return

    area = db.query(Area).filter(
        Area.id == area_id
    ).first()

    if not area:
        raise HTTPException(
            status_code=400,
            detail="Area tidak ditemukan",
        )


def validate_sales(db: Session, sales_id: int | None):
    if sales_id is None:
        return

    sales = db.query(User).filter(
        User.id == sales_id,
        User.role == "SALES",
        User.is_active == 1,
    ).first()

    if not sales:
        raise HTTPException(
            status_code=400,
            detail="Sales tidak ditemukan, tidak aktif, atau role bukan SALES",
        )


@router.get("/", response_model=list[CustomerResponse])
def get_customers(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(Customer)

    if current_user.role == "SALES":
        query = query.filter(Customer.sales_id == current_user.id)
    elif current_user.role not in CUSTOMER_VIEW_ROLES:
        raise HTTPException(
            status_code=403,
            detail="Kamu tidak memiliki akses ke data customer",
        )

    return query.order_by(Customer.id.desc()).all()


@router.get("/{customer_id}", response_model=CustomerResponse)
def get_customer(
    customer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    customer = db.query(Customer).filter(
        Customer.id == customer_id
    ).first()

    if not customer:
        raise HTTPException(
            status_code=404,
            detail="Customer tidak ditemukan",
        )

    if current_user.role == "SALES":
        if customer.sales_id != current_user.id:
            raise HTTPException(
                status_code=403,
                detail="Customer ini bukan tanggung jawabmu",
            )
    elif current_user.role not in CUSTOMER_VIEW_ROLES:
        raise HTTPException(
            status_code=403,
            detail="Kamu tidak memiliki akses ke data customer",
        )

    return customer


@router.post("/", response_model=CustomerResponse, status_code=201)
def create_customer(
    data: CustomerCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SALES", "SUPERADMIN", "SPV")
    ),
):
    if current_user.role == "SALES":
        if current_user.area_id is None:
            raise HTTPException(
                status_code=400,
                detail="Akun Anda belum memiliki area",
            )

        # Sales hanya bisa mengajukan customer untuk dirinya sendiri, di areanya sendiri.
        # sales_id dan area_id dari request diabaikan.
        customer = Customer(
            **data.model_dump(exclude={"sales_id", "area_id"}),
            sales_id=current_user.id,
            area_id=current_user.area_id,
            approval_status="PENDING",
        )
    else:
        validate_sales(db, data.sales_id)
        validate_area(db, data.area_id)

        customer = Customer(
            **data.model_dump(),
            approval_status="APPROVED",
            verified_by=current_user.id,
            verified_at=datetime.now(timezone.utc),
        )

    db.add(customer)
    db.commit()
    db.refresh(customer)

    return customer


@router.patch("/{customer_id}", response_model=CustomerResponse)
def update_customer(
    customer_id: int,
    data: CustomerUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SALES", "SPV", "SUPERADMIN")
    ),
):
    customer = db.query(Customer).filter(
        Customer.id == customer_id
    ).first()

    if not customer:
        raise HTTPException(
            status_code=404,
            detail="Customer tidak ditemukan",
        )

    updates = data.model_dump(exclude_unset=True)

    if current_user.role == "SALES":
        if customer.sales_id != current_user.id:
            raise HTTPException(
                status_code=403,
                detail="Customer ini bukan tanggung jawabmu",
            )

        if customer.approval_status == "APPROVED":
            raise HTTPException(
                status_code=403,
                detail="Customer yang sudah disetujui tidak bisa diedit oleh Sales",
            )

        # Sales tidak boleh memindahkan kepemilikan maupun area.
        updates.pop("sales_id", None)
        updates.pop("area_id", None)

    else:
        if "area_id" in updates:
            validate_area(db, updates["area_id"])

        if "sales_id" in updates:
            validate_sales(db, updates["sales_id"])

    for field, value in updates.items():
        setattr(customer, field, value)

    # Setiap perubahan oleh Sales mengajukan ulang customer ke SPV.
    if current_user.role == "SALES":
        customer.approval_status = "PENDING"
        customer.verified_by = None
        customer.verified_at = None
        customer.rejection_reason = None

    db.commit()
    db.refresh(customer)

    return customer


@router.patch("/{customer_id}/approve", response_model=CustomerResponse)
def approve_customer(
    customer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SPV", "SUPERADMIN")
    ),
):
    customer = db.query(Customer).filter(
        Customer.id == customer_id
    ).first()

    if not customer:
        raise HTTPException(
            status_code=404,
            detail="Customer tidak ditemukan",
        )

    if customer.approval_status == "APPROVED":
        raise HTTPException(
            status_code=400,
            detail="Customer sudah disetujui",
        )

    customer.approval_status = "APPROVED"
    customer.verified_by = current_user.id
    customer.verified_at = datetime.now(timezone.utc)
    customer.rejection_reason = None

    db.commit()
    db.refresh(customer)

    return customer


@router.delete("/{customer_id}", status_code=204)
def delete_customer(
    customer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV")
    ),
):
    customer = db.query(Customer).filter(
        Customer.id == customer_id
    ).first()

    if not customer:
        raise HTTPException(
            status_code=404,
            detail="Customer tidak ditemukan",
        )

    db.delete(customer)
    db.commit()

    return Response(status_code=204)


class CustomerRejectRequest(BaseModel):
    alasan: str = Field(min_length=1, max_length=1000)


@router.patch("/{customer_id}/reject", response_model=CustomerResponse)
def reject_customer(
    customer_id: int,
    data: CustomerRejectRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SPV", "SUPERADMIN")
    ),
):
    alasan = data.alasan.strip()

    if not alasan:
        raise HTTPException(
            status_code=422,
            detail="Alasan penolakan wajib diisi",
        )

    customer = db.query(Customer).filter(
        Customer.id == customer_id
    ).first()

    if not customer:
        raise HTTPException(
            status_code=404,
            detail="Customer tidak ditemukan",
        )

    if customer.approval_status == "APPROVED":
        raise HTTPException(
            status_code=400,
            detail="Customer yang sudah disetujui tidak bisa ditolak",
        )

    customer.approval_status = "REJECTED"
    customer.verified_by = current_user.id
    customer.verified_at = datetime.now(timezone.utc)
    customer.rejection_reason = alasan

    db.commit()
    db.refresh(customer)

    return customer