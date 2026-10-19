
from pathlib import Path
from uuid import uuid4

from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    UploadFile,
)
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.lkh import LKH
from app.models.lkh_attachment import LKHAttachment
from app.models.user import User
from app.core.dependencies import get_current_user

router = APIRouter(prefix="/lkh", tags=["LKH Attachments"])

# Lokasi file relatif terhadap direktori backend.
UPLOAD_DIR = Path(__file__).resolve().parents[2] / "uploads" / "lkh"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

ALLOWED_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "application/pdf": ".pdf",
}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5 MB


def get_accessible_lkh(
    lkh_id: int,
    db: Session,
    current_user: User,
) -> LKH:
    laporan = db.query(LKH).filter(LKH.id == lkh_id).first()

    if not laporan:
        raise HTTPException(404, "LKH tidak ditemukan")

    if current_user.role in ("SUPERADMIN", "SPV"):
        return laporan

    if current_user.role == "SALES":
        if laporan.sales_id == current_user.id:
            return laporan

        raise HTTPException(
            403,
            "Kamu tidak memiliki akses ke laporan ini",
        )

    raise HTTPException(
        403,
        "Kamu tidak memiliki akses ke lampiran LKH",
    )


@router.post("/{lkh_id}/attachments", status_code=201)
def upload_attachment(
    lkh_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    get_accessible_lkh(lkh_id, db, current_user)

    extension = ALLOWED_TYPES.get(file.content_type)

    if not extension:
        raise HTTPException(
            400,
            "Format file harus JPG, PNG, atau PDF",
        )

    content = file.file.read(MAX_FILE_SIZE + 1)

    if not content:
        raise HTTPException(400, "File kosong")

    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(413, "Ukuran file maksimal 5 MB")

    filename = f"{uuid4().hex}{extension}"
    destination = UPLOAD_DIR / filename

    try:
        destination.write_bytes(content)

        attachment = LKHAttachment(
            lkh_id=lkh_id,
            nama_file=Path(file.filename or "lampiran").name,
            file_url=filename,
            tipe_file=file.content_type,
        )

        db.add(attachment)
        db.commit()
        db.refresh(attachment)

    except Exception:
        db.rollback()
        destination.unlink(missing_ok=True)
        raise HTTPException(500, "Gagal menyimpan lampiran")

    return {
        "id": attachment.id,
        "lkh_id": attachment.lkh_id,
        "nama_file": attachment.nama_file,
        "tipe_file": attachment.tipe_file,
        "url": f"/lkh/attachments/{attachment.id}/file",
    }


@router.get("/attachments/{attachment_id}/file")
def get_attachment(
    attachment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    attachment = db.query(LKHAttachment).filter(
        LKHAttachment.id == attachment_id
    ).first()

    if not attachment:
        raise HTTPException(404, "Lampiran tidak ditemukan")

    get_accessible_lkh(attachment.lkh_id, db, current_user)

    # Pastikan file tetap berada di direktori upload.
    path = (UPLOAD_DIR / attachment.file_url).resolve()

    if path.parent != UPLOAD_DIR.resolve():
        raise HTTPException(400, "Lokasi file tidak valid")

    if not path.is_file():
        raise HTTPException(404, "File tidak ditemukan")

    return FileResponse(
        path,
        media_type=attachment.tipe_file,
        filename=attachment.nama_file,
        content_disposition_type="attachment",
    )


@router.get("/{lkh_id}/attachments")
def list_attachments(
    lkh_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    get_accessible_lkh(lkh_id, db, current_user)

    attachments = db.query(LKHAttachment).filter(
        LKHAttachment.lkh_id == lkh_id
    ).all()

    return [
        {
            "id": item.id,
            "nama_file": item.nama_file,
            "tipe_file": item.tipe_file,
            "url": f"/lkh/attachments/{item.id}/file",
        }
        for item in attachments
    ]
