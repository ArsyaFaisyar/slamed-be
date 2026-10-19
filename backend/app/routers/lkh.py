
from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.rkh import RKH
from app.models.lkh import LKH
from app.models.user import User
from app.schemas.lkh import LKHCreate, LKHUpdate, LKHResponse
from app.core.dependencies import get_current_user, require_roles

router = APIRouter(prefix="/lkh", tags=["LKH"])


def get_lkh_query(db: Session, current_user: User):
    query = db.query(LKH)

    if current_user.role == "SALES":
        query = query.filter(LKH.sales_id == current_user.id)
    elif current_user.role not in ("SUPERADMIN", "SPV"):
        raise HTTPException(
            status_code=403,
            detail="Kamu tidak memiliki akses ke laporan kunjungan",
        )

    return query


@router.get("/", response_model=list[LKHResponse])
def get_lkh(
    rkh_id: int | None = None,
    sales_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = get_lkh_query(db, current_user)

    if rkh_id is not None:
        query = query.filter(LKH.rkh_id == rkh_id)

    if sales_id is not None:
        if (
            current_user.role == "SALES"
            and sales_id != current_user.id
        ):
            raise HTTPException(
                status_code=403,
                detail="Kamu tidak memiliki akses ke laporan sales lain",
            )

        query = query.filter(LKH.sales_id == sales_id)

    return query.order_by(LKH.id.desc()).all()


@router.get("/{lkh_id}", response_model=LKHResponse)
def get_lkh_detail(
    lkh_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    laporan = get_lkh_query(db, current_user).filter(
        LKH.id == lkh_id
    ).first()

    if not laporan:
        raise HTTPException(
            404,
            "Laporan tidak ditemukan atau kamu tidak memiliki akses",
        )

    return laporan


@router.post("/", response_model=LKHResponse, status_code=201)
def create_lkh(
    data: LKHCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV", "SALES")
    ),
):
    rkh = db.query(RKH).filter(
        RKH.id == data.rkh_id
    ).first()

    if not rkh:
        raise HTTPException(404, "RKH tidak ditemukan")

    if (
        current_user.role == "SALES"
        and rkh.sales_id != current_user.id
    ):
        raise HTTPException(
            status_code=403,
            detail="RKH ini bukan tanggung jawabmu",
        )

    laporan_data = data.model_dump()
    laporan_data.pop("sales_id", None)

    # Satu RKH hanya boleh memiliki satu LKH.
    existing_laporan = db.query(LKH).filter(
        LKH.rkh_id == rkh.id
    ).first()

    if existing_laporan:
        raise HTTPException(
            status_code=409,
            detail="RKH ini sudah memiliki laporan kunjungan",
        )

    laporan = LKH(
        **laporan_data,
        sales_id=rkh.sales_id,
    )

    db.add(laporan)
    db.commit()
    db.refresh(laporan)

    return laporan


@router.patch("/{lkh_id}", response_model=LKHResponse)
def update_lkh(
    lkh_id: int,
    data: LKHUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV", "SALES")
    ),
):
    laporan = get_lkh_query(db, current_user).filter(
        LKH.id == lkh_id
    ).first()

    if not laporan:
        raise HTTPException(
            404,
            "Laporan tidak ditemukan atau kamu tidak memiliki akses",
        )

    updates = data.model_dump(exclude_unset=True)

    # Kepemilikan laporan tidak boleh diubah lewat request.
    updates.pop("sales_id", None)
    updates.pop("rkh_id", None)

    for field, value in updates.items():
        setattr(laporan, field, value)

    db.commit()
    db.refresh(laporan)

    return laporan


@router.delete("/{lkh_id}", status_code=204)
def delete_lkh(
    lkh_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV", "SALES")
    ),
):
    laporan = get_lkh_query(db, current_user).filter(
        LKH.id == lkh_id
    ).first()

    if not laporan:
        raise HTTPException(
            404,
            "Laporan tidak ditemukan atau kamu tidak memiliki akses",
        )

    db.delete(laporan)
    db.commit()

    return Response(status_code=204)
