import os
import uuid
from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, Response, UploadFile, File, Form
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.rkh import RKH
from app.models.lkh import LKH
from app.models.user import User
from app.models.project_prospek import ProjectProspek
from app.schemas.lkh import LKHCreate, LKHUpdate, LKHResponse
from app.core.dependencies import get_current_user, require_roles
from datetime import date

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
        if current_user.role == "SALES" and sales_id != current_user.id:
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
    rkh_id: int = Form(...),
    tanggal_kunjungan: date = Form(...),
    hasil_kunjungan: str = Form(...),
    nama_pic: str = Form(...),
    nomor_pic: str = Form(...),
    tindak_lanjut: str | None = Form(None),
    tanggal_follow_up: date | None = Form(None),
    latitude: float | None = Form(None),
    longitude: float | None = Form(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV", "SALES")
    ),
):
    rkh = db.query(RKH).filter(RKH.id == rkh_id).first()

    if not rkh:
        raise HTTPException(404, "RKH tidak ditemukan")

    if current_user.role == "SALES" and rkh.sales_id != current_user.id:
        raise HTTPException(403, "RKH ini bukan tanggung jawabmu")

    existing = db.query(LKH).filter(LKH.rkh_id == rkh.id).first()
    if existing:
        raise HTTPException(409, "RKH ini sudah memiliki laporan kunjungan")

    try:
        laporan = LKH(
            rkh_id=rkh.id,
            sales_id=rkh.sales_id,
            tanggal_kunjungan=tanggal_kunjungan,
            hasil_kunjungan=hasil_kunjungan,
            nama_pic=nama_pic,
            nomor_pic=nomor_pic,
            tindak_lanjut=tindak_lanjut,
            tanggal_follow_up=tanggal_follow_up,
            latitude=latitude,
            longitude=longitude,
        )

        db.add(laporan)
        rkh.status = "CLOSED"
        db.commit()
        db.refresh(laporan)

        return laporan

    except Exception:
        db.rollback()
        raise

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

    for field, value in updates.items():
        setattr(laporan, field, value)

    if "status_lkh" in updates:
        rkh = db.query(RKH).filter(RKH.id == laporan.rkh_id).first()
        if rkh:
            rkh.status = "CLOSED" if laporan.status_lkh == "DONE" else "OPEN"

    try:
        db.commit()
        db.refresh(laporan)
        return laporan
    except Exception:
        db.rollback()
        raise

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