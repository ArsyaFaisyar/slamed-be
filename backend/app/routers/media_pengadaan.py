from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.core.dependencies import get_current_user, require_roles
from app.models.media_pengadaan import MediaPengadaan
from app.schemas.media_pengadaan import (
    MediaPengadaanCreate,
    MediaPengadaanUpdate,
    MediaPengadaanResponse,
)

router = APIRouter(
    prefix="/media-pengadaan",
    tags=["Media Pengadaan"],
)


@router.get("/", response_model=list[MediaPengadaanResponse])
def get_all_media(
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN", "SPV")),
):
    return db.query(MediaPengadaan).order_by(MediaPengadaan.id.desc()).all()


@router.get("/{media_id}", response_model=MediaPengadaanResponse)
def get_media(
    media_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN", "SPV")),
):
    media = db.query(MediaPengadaan).filter(
        MediaPengadaan.id == media_id
    ).first()

    if not media:
        raise HTTPException(status_code=404, detail="Media pengadaan tidak ditemukan")

    return media


@router.post("/", response_model=MediaPengadaanResponse, status_code=status.HTTP_201_CREATED)
def create_media(
    payload: MediaPengadaanCreate,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN")),
):
    nama = payload.nama.strip()

    if not nama:
        raise HTTPException(status_code=422, detail="Nama media tidak boleh kosong")

    duplicate = db.query(MediaPengadaan).filter(
        MediaPengadaan.nama == nama
    ).first()

    if duplicate:
        raise HTTPException(status_code=409, detail="Nama media sudah digunakan")

    media = MediaPengadaan(nama=nama)
    db.add(media)
    db.commit()
    db.refresh(media)

    return media


@router.patch("/{media_id}", response_model=MediaPengadaanResponse)
def update_media(
    media_id: int,
    payload: MediaPengadaanUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN")),
):
    media = db.query(MediaPengadaan).filter(
        MediaPengadaan.id == media_id
    ).first()

    if not media:
        raise HTTPException(status_code=404, detail="Media pengadaan tidak ditemukan")

    updates = payload.model_dump(exclude_unset=True)

    if "nama" in updates:
        nama = updates["nama"].strip() if updates["nama"] else ""

        if not nama:
            raise HTTPException(status_code=422, detail="Nama media tidak boleh kosong")

        duplicate = db.query(MediaPengadaan).filter(
            MediaPengadaan.id != media_id,
            MediaPengadaan.nama == nama,
        ).first()

        if duplicate:
            raise HTTPException(status_code=409, detail="Nama media sudah digunakan")

        media.nama = nama

    db.commit()
    db.refresh(media)

    return media


@router.delete("/{media_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_media(
    media_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN")),
):
    media = db.query(MediaPengadaan).filter(
        MediaPengadaan.id == media_id
    ).first()

    if not media:
        raise HTTPException(status_code=404, detail="Media pengadaan tidak ditemukan")

    db.delete(media)
    db.commit()