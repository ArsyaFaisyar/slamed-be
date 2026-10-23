from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.lkh import LKH
from app.models.rkh import RKH
from app.models.project_prospek import ProjectProspek
from app.models.project_status import ProjectStatus
from app.models.branch import Branch
from app.models.request_penawaran import RequestPenawaran
from app.models.request_penawaran_item import RequestPenawaranItem
from app.schemas.request_penawaran import (
    RequestPenawaranCreate,
    RequestPenawaranResponse,
    RequestPenawaranItemCreate,
    RequestPenawaranItemUpdate,
    RequestPenawaranItemResponse,
)
from app.models.media_pengadaan import MediaPengadaan
from datetime import datetime, timezone

router = APIRouter(
    prefix="/request-penawaran",
    tags=["Request Penawaran"],
)

def refresh_request_completion(db, request):
    items = (
        db.query(RequestPenawaranItem)
        .filter(
            RequestPenawaranItem.request_penawaran_id == request.id
        )
        .all()
    )

    semua_harga_lengkap = bool(items) and all(
        item.harga_modal is not None
        and item.harga_jual is not None
        for item in items
    )

    if semua_harga_lengkap and request.completed_at is None:
        request.completed_at = datetime.now(timezone.utc)
    elif not semua_harga_lengkap:
        request.completed_at = None

def get_request_access(db, request_id, user):
    request = db.query(RequestPenawaran).filter(
        RequestPenawaran.id == request_id
    ).first()
    if not request:
        raise HTTPException(404, "Request penawaran tidak ditemukan")
    lkh = db.query(LKH).filter(LKH.id == request.lkh_id).first()
    if user.role == "SALES" and lkh.sales_id != user.id:
        raise HTTPException(403, "Tidak memiliki akses")
    if user.role not in ("SALES", "SPV", "SUPERADMIN"):
        raise HTTPException(403, "Tidak memiliki akses")
    return request


@router.post("/", response_model=RequestPenawaranResponse, status_code=201)
def create_request(
    data: RequestPenawaranCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    if user.role not in ("SALES", "SPV", "SUPERADMIN"):
        raise HTTPException(403, "Tidak memiliki akses")

    lkh = db.query(LKH).filter(LKH.id == data.lkh_id).first()
    if not lkh:
        raise HTTPException(404, "LKH tidak ditemukan")

    if user.role == "SALES" and lkh.sales_id != user.id:
        raise HTTPException(403, "LKH bukan tanggung jawabmu")

    existing = db.query(RequestPenawaran).filter(
        RequestPenawaran.lkh_id == data.lkh_id
    ).first()

    if existing:
        raise HTTPException(409, "LKH ini sudah memiliki request penawaran")

    rkh = db.query(RKH).filter(RKH.id == lkh.rkh_id).first()
    project = db.query(ProjectProspek).filter(
        ProjectProspek.id == rkh.project_id
    ).first()

    status = db.query(ProjectStatus).filter(
        ProjectStatus.id == project.status_id
    ).first()

    if not status or status.nama.strip().casefold() != "request penawaran":
        raise HTTPException(
            400,
            "Status project harus Request Penawaran",
        )

    if data.branch_id is not None:
        branch = db.query(Branch).filter(
            Branch.id == data.branch_id
        ).first()
        if not branch:
            raise HTTPException(404, "Branch/PT tidak ditemukan")
    if data.media_pengadaan_id is not None:
        media = (
            db.query(MediaPengadaan)
            .filter(MediaPengadaan.id == data.media_pengadaan_id)
            .first()
        )

        if not media:
            raise HTTPException(
                status_code=400,
                detail="Media pengadaan tidak ditemukan",
            )

    request = RequestPenawaran(**data.model_dump())

    try:
        db.add(request)
        db.commit()
        db.refresh(request)
        return request

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Data terkait tidak valid atau sudah terdaftar.",
        )

    except SQLAlchemyError:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Terjadi kesalahan saat menyimpan Request Penawaran.",
        )  raise HTTPException(
                status_code=409,
                detail="Data tidak dapat disimpan karena terkait dengan data lain yang tidak valid atau sudah terdaftar.",
            )

@router.get("/{request_id}", response_model=RequestPenawaranResponse)
def get_request(
    request_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return get_request_access(db, request_id, user)

@router.get(
    "/{request_id}/items",
    response_model=list[RequestPenawaranItemResponse],
)
def get_items(
    request_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    get_request_access(db, request_id, user)
    return db.query(RequestPenawaranItem).filter(
        RequestPenawaranItem.request_penawaran_id == request_id
    ).order_by(RequestPenawaranItem.id.asc()).all()


@router.post(
    "/{request_id}/items",
    response_model=RequestPenawaranItemResponse,
    status_code=201,
)
def create_item(
    request_id: int,
    data: RequestPenawaranItemCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    request = get_request_access(db, request_id, user)
    item = RequestPenawaranItem(
        request_penawaran_id=request_id,
        **data.model_dump(),
    )
    try:
        db.add(item)
        db.flush()

        refresh_request_completion(db, request)
        db.commit()
        db.refresh(item)
        return item
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Item tidak dapat disimpan karena data tidak valid.",
        )
    except SQLAlchemyError:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Terjadi kesalahan saat menyimpan item.",
        )

@router.patch(
    "/{request_id}/items/{item_id}",
    response_model=RequestPenawaranItemResponse,
)
def update_item(
    request_id: int,
    item_id: int,
    data: RequestPenawaranItemUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    request = get_request_access(db, request_id, user)
    item = db.query(RequestPenawaranItem).filter(
        RequestPenawaranItem.id == item_id,
        RequestPenawaranItem.request_penawaran_id == request_id,
    ).first()

    if not item:
        raise HTTPException(404, "Item tidak ditemukan")

    updates = data.model_dump(exclude_unset=True)

    if user.role == "SALES":
        restricted = {"harga_modal", "harga_jual"}
        if restricted.intersection(updates):
            raise HTTPException(
                403,
                "Sales tidak dapat mengubah harga modal atau harga jual",
            )

    for field, value in updates.items():
        setattr(item, field, value)

    try:
        refresh_request_completion(db, request)
        db.commit()
        db.refresh(item)
        return item
    except Exception:
        db.rollback()
        raise
@router.delete("/{request_id}/items/{item_id}")
def delete_item(
    request_id: int,
    item_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    request = get_request_access(db, request_id, user)
    item = (
        db.query(RequestPenawaranItem)
        .filter(
            RequestPenawaranItem.id == item_id,
            RequestPenawaranItem.request_penawaran_id == request_id,
        )
        .first()
    )

    if not item:
        raise HTTPException(
            status_code=404,
            detail="Item tidak ditemukan dalam Request Penawaran ini.",
        )

    try:
        db.delete(item)
        db.flush()

        refresh_request_completion(db, request)
        db.commit()

        return {"message": "Item berhasil dihapus."}
    except SQLAlchemyError:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Terjadi kesalahan saat menghapus item.",
        )