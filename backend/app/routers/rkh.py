
from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.customer import Customer
from app.models.project_prospek import ProjectProspek
from app.models.rkh import RKH
from app.models.user import User
from app.schemas.rkh import RKHCreate, RKHUpdate, RKHResponse
from app.core.dependencies import get_current_user, require_roles

router = APIRouter(prefix="/rkh", tags=["RKH"])


def validate_customer_project(
    db: Session,
    customer_id: int,
    project_id: int,
):
    customer = db.query(Customer).filter(
        Customer.id == customer_id
    ).first()

    if not customer:
        raise HTTPException(404, "Customer tidak ditemukan")

    project = db.query(ProjectProspek).filter(
        ProjectProspek.id == project_id,
        ProjectProspek.customer_id == customer_id,
    ).first()

    if not project:
        raise HTTPException(
            400,
            "Project tidak ditemukan atau bukan milik customer tersebut",
        )

    if customer.sales_id is None:
        raise HTTPException(
            400,
            "Customer belum ditugaskan ke sales",
        )

    return customer


def get_rkh_query(db: Session, current_user: User):
    query = db.query(RKH)

    if current_user.role == "SALES":
        query = query.filter(RKH.sales_id == current_user.id)
    elif current_user.role not in ("SUPERADMIN", "SPV"):
        raise HTTPException(
            status_code=403,
            detail="Kamu tidak memiliki akses ke RKH",
        )

    return query


@router.get("/", response_model=list[RKHResponse])
def get_rkh(
    sales_id: int | None = None,
    customer_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = get_rkh_query(db, current_user)

    if sales_id is not None:
        # Sales tidak bisa mengganti filter untuk melihat RKH orang lain.
        if (
            current_user.role == "SALES"
            and sales_id != current_user.id
        ):
            raise HTTPException(
                status_code=403,
                detail="Kamu tidak memiliki akses ke RKH sales lain",
            )

        query = query.filter(RKH.sales_id == sales_id)

    if customer_id is not None:
        query = query.filter(RKH.customer_id == customer_id)

    return query.order_by(RKH.id.desc()).all()


@router.get("/{rkh_id}", response_model=RKHResponse)
def get_rkh_detail(
    rkh_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    rkh = get_rkh_query(db, current_user).filter(
        RKH.id == rkh_id
    ).first()

    if not rkh:
        raise HTTPException(
            404,
            "RKH tidak ditemukan atau kamu tidak memiliki akses",
        )

    return rkh


@router.post("/", response_model=RKHResponse, status_code=201)
def create_rkh(
    data: RKHCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV", "SALES")
    ),
):
    customer = validate_customer_project(
        db, data.customer_id, data.project_id
    )

    if current_user.role == "SALES":
        if customer.sales_id != current_user.id:
            raise HTTPException(
                status_code=403,
                detail="Customer ini bukan tanggung jawabmu",
            )

    rkh_data = data.model_dump()
    rkh_data.pop("sales_id", None)

    rkh = RKH(
        **rkh_data,
        sales_id=customer.sales_id,
    )

    db.add(rkh)
    db.commit()
    db.refresh(rkh)

    return rkh


@router.patch("/{rkh_id}", response_model=RKHResponse)
def update_rkh(
    rkh_id: int,
    data: RKHUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV", "SALES")
    ),
):
    rkh = get_rkh_query(db, current_user).filter(
        RKH.id == rkh_id
    ).first()

    if not rkh:
        raise HTTPException(
            404,
            "RKH tidak ditemukan atau kamu tidak memiliki akses",
        )

    updates = data.model_dump(exclude_unset=True)
    updates.pop("sales_id", None)

    customer_id = updates.get("customer_id", rkh.customer_id)
    project_id = updates.get("project_id", rkh.project_id)

    customer = validate_customer_project(
        db, customer_id, project_id
    )

    if current_user.role == "SALES":
        if customer.sales_id != current_user.id:
            raise HTTPException(
                status_code=403,
                detail="Customer ini bukan tanggung jawabmu",
            )

    for field, value in updates.items():
        setattr(rkh, field, value)

    rkh.sales_id = customer.sales_id

    db.commit()
    db.refresh(rkh)

    return rkh


@router.delete("/{rkh_id}", status_code=204)
def delete_rkh(
    rkh_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV", "SALES")
    ),
):
    rkh = get_rkh_query(db, current_user).filter(
        RKH.id == rkh_id
    ).first()

    if not rkh:
        raise HTTPException(
            404,
            "RKH tidak ditemukan atau kamu tidak memiliki akses",
        )

    db.delete(rkh)
    db.commit()
    return Response(status_code=204)
