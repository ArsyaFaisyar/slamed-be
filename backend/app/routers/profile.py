from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.core.dependencies import get_current_user
from app.core.security import hash_password, verify_password
from app.schemas.users import ChangePasswordRequest


router = APIRouter(prefix="/profile", tags=["Profile"])

PROFILE_DIR = (
    Path(__file__).resolve().parents[2]
    / "uploads"
    / "profiles"
)

ALLOWED_IMAGE_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}

MAX_IMAGE_SIZE = 5 * 1024 * 1024


@router.get("/")
def get_profile(
    current_user: User = Depends(get_current_user),
):
    return {
        "id": current_user.id,
        "nama": current_user.nama,
        "username": current_user.username,
        "email": current_user.email,
        "role": current_user.role,
        "foto_profil": current_user.foto_profil,
    }


@router.patch("/password")
def change_password(
    data: ChangePasswordRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not verify_password(
        data.password_lama,
        current_user.password_hash,
    ):
        raise HTTPException(
            status_code=400,
            detail="Password lama salah",
        )

    if data.password_lama == data.password_baru:
        raise HTTPException(
            status_code=400,
            detail="Password baru harus berbeda",
        )

    current_user.password_hash = hash_password(data.password_baru)

    try:
        db.commit()
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Gagal mengganti password",
        )

    return {"message": "Password berhasil diganti"}


@router.post("/photo")
def change_profile_photo(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    extension = ALLOWED_IMAGE_TYPES.get(file.content_type)

    if not extension:
        raise HTTPException(
            status_code=400,
            detail="Foto harus berformat JPG, PNG, atau WEBP",
        )

    content = file.file.read(MAX_IMAGE_SIZE + 1)

    if not content or len(content) > MAX_IMAGE_SIZE:
        raise HTTPException(
            status_code=400,
            detail="Foto kosong atau melebihi batas 5 MB",
        )

    valid_signature = (
        (extension == ".jpg" and content.startswith(b"\xff\xd8\xff"))
        or (
            extension == ".png"
            and content.startswith(b"\x89PNG\r\n\x1a\n")
        )
        or (
            extension == ".webp"
            and content.startswith(b"RIFF")
            and content[8:12] == b"WEBP"
        )
    )

    if not valid_signature:
        raise HTTPException(
            status_code=400,
            detail="Isi file tidak sesuai dengan format gambar",
        )

    PROFILE_DIR.mkdir(parents=True, exist_ok=True)

    filename = f"{uuid4().hex}{extension}"
    destination = PROFILE_DIR / filename
    old_filename = current_user.foto_profil

    try:
        destination.write_bytes(content)
        current_user.foto_profil = filename
        db.commit()
        db.refresh(current_user)
    except Exception:
        db.rollback()
        destination.unlink(missing_ok=True)
        raise HTTPException(
            status_code=500,
            detail="Gagal menyimpan foto profil",
        )

    if old_filename:
        old_path = PROFILE_DIR / Path(old_filename).name
        if old_path != destination:
            old_path.unlink(missing_ok=True)

    return {
        "message": "Foto profil berhasil diperbarui",
        "foto_profil": filename,
    }


@router.get("/photo")
def get_profile_photo(
    current_user: User = Depends(get_current_user),
):
    if not current_user.foto_profil:
        raise HTTPException(
            status_code=404,
            detail="Foto profil belum diatur",
        )

    path = (
        PROFILE_DIR / Path(current_user.foto_profil).name
    ).resolve()

    if path.parent != PROFILE_DIR.resolve() or not path.is_file():
        raise HTTPException(
            status_code=404,
            detail="Foto profil tidak ditemukan",
        )

    return FileResponse(path)