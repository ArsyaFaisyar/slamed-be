from pathlib import Path
from uuid import uuid4

from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
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

UPLOAD_DIR = Path(__file__).resolve().parents[2] / "uploads" / "lkh"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

RULES = {
    "FOTO": (
        {
            "image/jpeg": ".jpg",
            "image/png": ".png",
            "image/gif": ".gif",
        },
        2 * 1024 * 1024,
    ),
    "LAMPIRAN": (
        {
            "application/pdf": ".pdf",
            "application/msword": ".doc",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document": ".docx",
            "application/vnd.ms-excel": ".xls",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": ".xlsx",
        },
        5 * 1024 * 1024,
    ),
}


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


def serialize(item: LKHAttachment) -> dict:
    return {
        "id": item.id,
        "lkh_id": item.lkh_id,
        "nama_file": item.nama_file,
        "tipe_file": item.tipe_file,
        "jenis": item.jenis,
        "url": f"/lkh/attachments/{item.id}/file",
    }


@router.post("/{lkh_id}/attachments", status_code=201)
def upload_attachment(
    lkh_id: int,
    file: UploadFile = File(...),
    jenis: str = Form(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    laporan = get_accessible_lkh(lkh_id, db, current_user)

    if jenis not in RULES:
        raise HTTPException(400, "Jenis file harus FOTO atau LAMPIRAN")

    allowed_types, max_size = RULES[jenis]
    extension = allowed_types.get(file.content_type)

    if not extension:
        raise HTTPException(400, "Format file tidak sesuai jenisnya")

    content = file.file.read(max_size + 1)
    if not content:
        raise HTTPException(400, "File kosong")
    if len(content) > max_size:
        raise HTTPException(413, "Ukuran file melebihi batas")

    # Satu file per jenis: unggahan baru menggantikan yang lama.
    old_items = db.query(LKHAttachment).filter(
        LKHAttachment.lkh_id == lkh_id,
        LKHAttachment.jenis == jenis,
    ).all()
    old_files = [item.file_url for item in old_items]

    filename = f"{uuid4().hex}{extension}"
    destination = UPLOAD_DIR / filename

    try:
        destination.write_bytes(content)

        for item in old_items:
            db.delete(item)

        attachment = LKHAttachment(
            lkh_id=lkh_id,
            nama_file=Path(file.filename or "lampiran").name,
            file_url=filename,
            tipe_file=file.content_type,
            jenis=jenis,
        )
        db.add(attachment)

        if jenis == "FOTO":
            laporan.status_lkh = "DONE"

        db.commit()
        db.refresh(attachment)

    except Exception:
        db.rollback()
        destination.unlink(missing_ok=True)
        raise HTTPException(500, "Gagal menyimpan lampiran")

    for name in old_files:
        (UPLOAD_DIR / name).unlink(missing_ok=True)

    return serialize(attachment)


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

    attachments = (
        db.query(LKHAttachment)
        .filter(LKHAttachment.lkh_id == lkh_id)
        .order_by(LKHAttachment.id)
        .all()
    )

    return [serialize(item) for item in attachments]