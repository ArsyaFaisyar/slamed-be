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
    foto: UploadFile = File(...),
    file_lampiran: UploadFile | None = File(None),
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

    allowed_photo = {"image/jpeg", "image/png", "image/gif"}
    allowed_attachment = {
        "application/pdf",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.ms-excel",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    }

    if foto.content_type not in allowed_photo:
        raise HTTPException(400, "Foto harus JPG, PNG, atau GIF")

    if file_lampiran and file_lampiran.content_type not in allowed_attachment:
        raise HTTPException(400, "Lampiran harus PDF, DOC, DOCX, XLS, atau XLSX")

    upload_dir = Path("uploads/lkh")
    upload_dir.mkdir(parents=True, exist_ok=True)

    saved_files = []

    try:
        def save_upload(upload: UploadFile, max_size: int) -> str:
            extension = Path(upload.filename or "").suffix.lower()
            content = upload.file.read(max_size + 1)

            if len(content) > max_size:
                raise HTTPException(400, "Ukuran file terlalu besar")

            filename = f"{uuid.uuid4().hex}{extension}"
            destination = upload_dir / filename
            destination.write_bytes(content)
            saved_files.append(destination)

            return str(destination).replace("\\", "/")

        foto_path = save_upload(foto, 2 * 1024 * 1024)

        lampiran_path = None
        if file_lampiran:
            lampiran_path = save_upload(
                file_lampiran,
                5 * 1024 * 1024,
            )

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
            foto_path=foto_path,
            file_lampiran_path=lampiran_path,
        )

        db.add(laporan)
        db.commit()
        db.refresh(laporan)

        return laporan

    except Exception:
        db.rollback()

        for path in saved_files:
            path.unlink(missing_ok=True)

        raise

    finally:
        foto.file.close()
        if file_lampiran:
            file_lampiran.file.close()

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