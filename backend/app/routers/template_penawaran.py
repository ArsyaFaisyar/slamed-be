import os
from uuid import uuid4
from pathlib import Path

from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    UploadFile,
)
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.template_penawaran import TemplatePenawaran
from app.schemas.template_penawaran import (
    TemplatePenawaranCreate,
    TemplatePenawaranUpdate,
    TemplatePenawaranResponse,
)
from app.core.dependencies import get_current_user, require_roles
from app.models.user import User


router = APIRouter(
    prefix="/template-penawaran",
    tags=["Template Penawaran"],
)

UPLOAD_DIR = Path("uploads/template_penawaran")
MAX_FILE_SIZE = 5 * 1024 * 1024
ALLOWED_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}


@router.get("/", response_model=list[TemplatePenawaranResponse])
def get_templates(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(TemplatePenawaran)
        .order_by(TemplatePenawaran.id.desc())
        .all()
    )

@router.get("/{template_id}", response_model=TemplatePenawaranResponse)
def get_template(
    template_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    template = db.query(TemplatePenawaran).filter(
        TemplatePenawaran.id == template_id
    ).first()

    if not template:
        raise HTTPException(404, "Template tidak ditemukan")

    return template

@router.post(
    "/",
    response_model=TemplatePenawaranResponse,
    status_code=201,
)
def create_template(
    data: TemplatePenawaranCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN")
    ),
):
    template = TemplatePenawaran(
        judul=data.judul.strip(),
        konten=data.konten,
        created_by=current_user.id,
    )
    db.add(template)
    db.commit()
    db.refresh(template)
    return template

@router.patch(
    "/{template_id}",
    response_model=TemplatePenawaranResponse,
)
def update_template(
    template_id: int,
    data: TemplatePenawaranUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN")
    ),
):
    template = db.query(TemplatePenawaran).filter(
        TemplatePenawaran.id == template_id
    ).first()
    if not template:
        raise HTTPException(404, "Template tidak ditemukan")
    updates = data.model_dump(exclude_unset=True)
    if "judul" in updates and updates["judul"] is not None:
        updates["judul"] = updates["judul"].strip()
    for field, value in updates.items():
        if value is not None:
            setattr(template, field, value)
    db.commit()
    db.refresh(template)
    return template

@router.post("/{template_id}/preview")
def upload_template_preview(
    template_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN")
    ),
):
    template = db.query(TemplatePenawaran).filter(
        TemplatePenawaran.id == template_id
    ).first()
    if not template:
        raise HTTPException(404, "Template tidak ditemukan")
    extension = ALLOWED_TYPES.get(file.content_type or "")
    if not extension:
        raise HTTPException(
            400,
            "Format preview harus JPG, PNG, atau WebP",
        )
    content = file.file.read(MAX_FILE_SIZE + 1)
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            413,
            "Ukuran preview maksimal 5 MB",
        )
    if not content:
        raise HTTPException(400, "File preview kosong")
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    filename = f"{uuid4().hex}{extension}"
    destination = UPLOAD_DIR / filename
    try:
        with destination.open("wb") as output:
            output.write(content)
        old_path = template.preview_path
        template.preview_path = str(destination).replace("\\", "/")
        db.commit()
        db.refresh(template)
    except Exception:
        db.rollback()
        if destination.exists():
            destination.unlink()
        raise HTTPException(
            500,
            "Gagal menyimpan preview template",
        )
    if old_path:
        old_file = Path(old_path)
        if old_file.is_file() and old_file.parent == UPLOAD_DIR:
            old_file.unlink(missing_ok=True)
    return {
        "message": "Preview berhasil diunggah",
        "preview_path": template.preview_path,
    }

@router.delete("/{template_id}", status_code=204)
def delete_template(
    template_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN")
    ),
):
    template = db.query(TemplatePenawaran).filter(
        TemplatePenawaran.id == template_id
    ).first()
    if not template:
        raise HTTPException(404, "Template tidak ditemukan")
    preview_path = template.preview_path
    db.delete(template)
    db.commit()
    if preview_path:
        old_file = Path(preview_path)
        if old_file.is_file() and old_file.parent == UPLOAD_DIR:
            old_file.unlink(missing_ok=True)
    from fastapi import Response
    return Response(status_code=204)
