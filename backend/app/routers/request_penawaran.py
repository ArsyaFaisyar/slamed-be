from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session

import os
from decimal import Decimal
from uuid import uuid4
from pathlib import Path
from pydantic import BaseModel, Field, HttpUrl
from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.core.roles import REQUEST_EDIT_ROLES, REQUEST_VIEW_ROLES
from app.models.user import User
from app.models.lkh import LKH
from app.models.rkh import RKH
from app.models.project_prospek import ProjectProspek
from app.models.project_status import ProjectStatus
from app.models.branch import Branch
from app.models.request_penawaran import RequestPenawaran
from app.models.request_penawaran_item import RequestPenawaranItem
from app.models.customer import Customer
from app.schemas.request_penawaran import (
    RequestPenawaranCreate,
    RequestPenawaranUpdate,
    RequestPenawaranResponse,
    RequestPenawaranItemCreate,
    RequestPenawaranItemUpdate,
    RequestPenawaranItemResponse,
)
from app.schemas.revisi_penawaran import RevisiPenawaranUpdate
from app.models.revisi_penawaran import RevisiPenawaran
from app.models.revisi_penawaran_item import RevisiPenawaranItem
from app.schemas.revisi_penawaran import RevisiPenawaranCreate
from app.models.revisi_penawaran_arsip_item import RevisiPenawaranArsipItem
from app.models.media_pengadaan import MediaPengadaan
from datetime import datetime, timezone
from app.utils.project_log import catat_project_log

router = APIRouter(
    prefix="/request-penawaran",
    tags=["Request Penawaran"],
)
UPLOAD_DIR = Path("uploads/request_penawaran")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

MAX_IMAGE_SIZE = 5 * 1024 * 1024
ALLOWED_IMAGE_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}


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


def hitung_ulang_total(db: Session, request: RequestPenawaran) -> None:
    """Hitung ulang total request dari barang-barangnya.

    - total_pagu: hanya barang non-tambahan, dan hanya pada mode DETAIL.
      Pada mode TOTAL nilai yang diinput manual dipertahankan.
    - total_harga_modal dan total_harga_jual: semua barang (termasuk tambahan PPIC).
    """
    db.flush()

    items = (
        db.query(RequestPenawaranItem)
        .filter(RequestPenawaranItem.request_penawaran_id == request.id)
        .all()
    )

    def jumlah_harga(kolom: str, termasuk_tambahan: bool) -> Decimal:
        hasil = Decimal("0")
        for item in items:
            if item.is_tambahan and not termasuk_tambahan:
                continue
            harga = getattr(item, kolom)
            if harga is None:
                continue
            hasil += (item.jumlah or Decimal("0")) * harga
        return hasil

    if request.mode_pagu == "DETAIL":
        request.total_pagu = jumlah_harga("harga_pagu", termasuk_tambahan=False)

    request.total_harga_modal = jumlah_harga("harga_modal", termasuk_tambahan=True)
    request.total_harga_jual = jumlah_harga("harga_jual", termasuk_tambahan=True)


REQUEST_STATUS_KEYS = ("request penawaran", "req penawaran", "penawaran")

# Yang boleh diubah PPIC pada barang input sales.
PPIC_ITEM_FIELDS = {
    "nama_barang",
    "merk",
    "tkdn",
    "tkdn_persen",
    "spesifikasi",
    "jenis_pajak",
    "harga_modal",
}

# Barang tambahan dibuat PPIC sendiri, jadi boleh diubah lebih lengkap.
PPIC_OWN_ITEM_FIELDS = PPIC_ITEM_FIELDS | {
    "jumlah",
    "satuan",
    "link_marketplace",
    "gambar_path",
}


def get_request_access(db, request_id, user, write=False):
    request = db.query(RequestPenawaran).filter(
        RequestPenawaran.id == request_id
    ).first()

    if not request:
        raise HTTPException(404, "Request penawaran tidak ditemukan")

    lkh = db.query(LKH).filter(LKH.id == request.lkh_id).first()

    if not lkh:
        raise HTTPException(404, "LKH tidak ditemukan")

    if user.role == "SALES" and lkh.sales_id != user.id:
        raise HTTPException(403, "Tidak memiliki akses")

    allowed = REQUEST_EDIT_ROLES if write else REQUEST_VIEW_ROLES

    if user.role not in allowed:
        raise HTTPException(403, "Tidak memiliki akses")

    return request


def get_project_from_request(db: Session, request):
    lkh = db.query(LKH).filter(LKH.id == request.lkh_id).first()
    if not lkh:
        return None

    rkh = db.query(RKH).filter(RKH.id == lkh.rkh_id).first()
    if not rkh:
        return None

    return db.query(ProjectProspek).filter(
        ProjectProspek.id == rkh.project_id
    ).first()


def get_item_or_404(db: Session, request_id: int, item_id: int):
    item = db.query(RequestPenawaranItem).filter(
        RequestPenawaranItem.id == item_id,
        RequestPenawaranItem.request_penawaran_id == request_id,
    ).first()

    if not item:
        raise HTTPException(404, "Item tidak ditemukan")

    return item


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
    if not rkh:
        raise HTTPException(404, "RKH tidak ditemukan")
    project = db.query(ProjectProspek).filter(
        ProjectProspek.id == rkh.project_id
    ).first()
    if not project:
        raise HTTPException(404, "Project tidak ditemukan")
    status = db.query(ProjectStatus).filter(
        ProjectStatus.id == project.status_id
    ).first()
    status_name = status.nama.strip().casefold() if status else ""
    if not any(key in status_name for key in REQUEST_STATUS_KEYS):
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
        media = db.query(MediaPengadaan).filter(
            MediaPengadaan.id == data.media_pengadaan_id
        ).first()

        if not media:
            raise HTTPException(
                status_code=400,
                detail="Media pengadaan tidak ditemukan",
            )

    customer = db.query(Customer).filter(
            Customer.id == project.customer_id
        ).first()

    if not customer:
        raise HTTPException(404, "Customer tidak ditemukan")

    request_data = data.model_dump()

    request_data["nama_pic"] = (
        data.nama_pic
        if data.nama_pic is not None
        else customer.nama_pic
    )

    request_data["nomor_pic"] = (
        data.nomor_pic
        if data.nomor_pic is not None
        else customer.kontak_pic
    )

    request = RequestPenawaran(**request_data)
    try:
        db.add(request)
        db.flush()

        catat_project_log(
            db=db,
            project_id=project.id,
            user_id=user.id,
            aktivitas="Request Penawaran dibuat",
            deskripsi=(
                f"Request Penawaran dibuat untuk project "
                f"{project.nama_project}."
            ),
        )


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
        )

@router.get("/", response_model=list[RequestPenawaranResponse])
def get_requests(
    lkh_id: int | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    if user.role not in REQUEST_VIEW_ROLES:
        raise HTTPException(403, "Tidak memiliki akses")

    query = db.query(RequestPenawaran)

    if user.role == "SALES":
        query = query.join(
            LKH,
            LKH.id == RequestPenawaran.lkh_id,
        ).filter(
            LKH.sales_id == user.id
        )

    if lkh_id is not None:
        query = query.filter(RequestPenawaran.lkh_id == lkh_id)

    return query.order_by(RequestPenawaran.id.desc()).all()


@router.get("/{request_id}", response_model=RequestPenawaranResponse)
def get_request(
    request_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return get_request_access(db, request_id, user)


@router.patch(
    "/{request_id}",
    response_model=RequestPenawaranResponse,
)
def update_request(
    request_id: int,
    data: RequestPenawaranUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    request = get_request_access(db, request_id, user, write=True)
    updates = data.model_dump(exclude_unset=True)

    if user.role == "SALES":
        restricted = {"total_pagu"}

        if restricted.intersection(updates):
            raise HTTPException(
                status_code=403,
                detail="Sales tidak dapat mengubah total pagu",
            )

    if user.role == "PPIC":
        # PPIC tidak mengubah data request (media, branch, mode pagu, total pagu).
        raise HTTPException(
            status_code=403,
            detail="PPIC tidak dapat mengubah data request penawaran",
        )

    if "mode_pagu" in updates:
        if updates["mode_pagu"] not in ("DETAIL", "TOTAL"):
            raise HTTPException(
                400,
                "Mode pagu harus DETAIL atau TOTAL",
            )

    if (
        "media_pengadaan_id" in updates
        and updates["media_pengadaan_id"] is not None
    ):
        media = db.query(MediaPengadaan).filter(
            MediaPengadaan.id == updates["media_pengadaan_id"]
        ).first()

        if not media:
            raise HTTPException(
                404,
                "Media pengadaan tidak ditemukan",
            )

    if "branch_id" in updates and updates["branch_id"] is not None:
        branch = db.query(Branch).filter(
            Branch.id == updates["branch_id"]
        ).first()

        if not branch:
            raise HTTPException(
                404,
                "Branch/PT tidak ditemukan",
            )

    for field, value in updates.items():
        setattr(request, field, value)

    try:
        # Pada mode DETAIL, total pagu selalu dihitung dari barang (bukan nilai kiriman).
        hitung_ulang_total(db, request)
        db.commit()
        db.refresh(request)
        return request
    except Exception:
        db.rollback()
        raise


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

    query = db.query(RequestPenawaranItem).filter(
        RequestPenawaranItem.request_penawaran_id == request_id
    )

    # Barang tambahan PPIC tidak ditampilkan ke Sales.
    if user.role == "SALES":
        query = query.filter(RequestPenawaranItem.is_tambahan.is_(False))

    return query.order_by(RequestPenawaranItem.id.asc()).all()


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
    request = get_request_access(db, request_id, user, write=True)

    values = data.model_dump()

    # Barang tambahan: otomatis untuk PPIC; SUPERADMIN/SPV memilihnya dari section harga modal.
    if user.role == "PPIC":
        values["is_tambahan"] = True
    elif user.role == "SALES":
        values["is_tambahan"] = False

    item = RequestPenawaranItem(
        request_penawaran_id=request_id,
        **values,
    )
    try:
        db.add(item)
        db.flush()

        project = get_project_from_request(db, request)
        if project:
            catat_project_log(
                db=db,
                project_id=project.id,
                user_id=user.id,
                aktivitas="Item Request Penawaran ditambahkan",
                deskripsi=(
                    f"Item {'tambahan ' if item.is_tambahan else ''}baru ditambahkan "
                    f"ke Request Penawaran #{request.id}."
                ),
            )

        hitung_ulang_total(db, request)
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
    request = get_request_access(db, request_id, user, write=True)
    item = get_item_or_404(db, request_id, item_id)

    updates = data.model_dump(exclude_unset=True)

    if user.role == "SALES":
        if item.is_tambahan:
            raise HTTPException(
                403,
                "Sales tidak dapat mengubah barang tambahan dari PPIC",
            )

        restricted = {"harga_modal", "harga_jual"}

        if restricted.intersection(updates):
            raise HTTPException(
                403,
                "Sales tidak dapat mengubah harga modal atau harga jual",
            )

    if user.role == "PPIC":
        allowed = PPIC_OWN_ITEM_FIELDS if item.is_tambahan else PPIC_ITEM_FIELDS

        if not allowed.issuperset(updates):
            raise HTTPException(
                403,
                "PPIC hanya dapat mengubah nama, merk, TKDN, spesifikasi, "
                "gambar, jenis pajak, dan harga modal"
                + (
                    " (barang tambahan: juga jumlah, satuan, dan link marketplace)"
                    if item.is_tambahan
                    else ""
                ),
            )

    # Barang tambahan tidak punya harga pagu (tidak masuk pagu/RAB).
    if item.is_tambahan and updates.get("harga_pagu") is not None:
        raise HTTPException(
            400,
            "Barang tambahan tidak memiliki harga pagu",
        )

    for field, value in updates.items():
        setattr(item, field, value)

    try:
        if updates:
            project = get_project_from_request(db, request)
            if project:
                catat_project_log(
                    db=db,
                    project_id=project.id,
                    user_id=user.id,
                    aktivitas="Item Request Penawaran diperbarui",
                    deskripsi=(
                        f"Item #{item.id} pada Request Penawaran "
                        f"#{request.id} diperbarui."
                    ),
                )

        hitung_ulang_total(db, request)
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
    request = get_request_access(db, request_id, user, write=True)
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

    if user.role == "PPIC" and not item.is_tambahan:
        raise HTTPException(
            status_code=403,
            detail="PPIC hanya dapat menghapus barang tambahan yang ia buat",
        )

    if user.role == "SALES" and item.is_tambahan:
        raise HTTPException(
            status_code=403,
            detail="Sales tidak dapat menghapus barang tambahan dari PPIC",
        )

    try:
        project = get_project_from_request(db, request)

        db.delete(item)
        db.flush()

        if project:
            catat_project_log(
                db=db,
                project_id=project.id,
                user_id=user.id,
                aktivitas="Item Request Penawaran dihapus",
                deskripsi=(
                    f"Item #{item.id} dihapus dari "
                    f"Request Penawaran #{request.id}."
                ),
            )

        hitung_ulang_total(db, request)
        refresh_request_completion(db, request)
        db.commit()

        return {"message": "Item berhasil dihapus."}
    except SQLAlchemyError:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Terjadi kesalahan saat menghapus item.",
        )



@router.post("/{request_id}/revisi", status_code=201)
def minta_revisi_penawaran(
    request_id: int,
    data: RevisiPenawaranCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "SPV":
        raise HTTPException(
            status_code=403,
            detail="Hanya SPV yang dapat meminta revisi penawaran",
        )

    alasan = data.alasan_revisi.strip()
    if not alasan:
        raise HTTPException(
            status_code=422,
            detail="Alasan revisi wajib diisi",
        )

    request = (
        db.query(RequestPenawaran)
        .filter(RequestPenawaran.id == request_id)
        .first()
    )
    if not request:
        raise HTTPException(
            status_code=404,
            detail="Request Penawaran tidak ditemukan",
        )

    revisi_terakhir = (
        db.query(RevisiPenawaran)
        .filter(
            RevisiPenawaran.request_penawaran_id == request_id
        )
        .order_by(RevisiPenawaran.nomor_revisi.desc())
        .first()
    )

    if revisi_terakhir:
        if revisi_terakhir.status_revisi == "SELESAI":
            raise HTTPException(
                status_code=400,
                detail="Revisi sudah disetujui. Permintaan revisi tidak dapat dilakukan lagi.",
            )

        if revisi_terakhir.status_revisi == "DIMINTA":
            raise HTTPException(
                status_code=400,
                detail="Revisi masih menunggu perbaikan Sales.",
            )

        if revisi_terakhir.status_revisi == "DIKIRIM":
            revisi_terakhir.status_revisi = "DITOLAK"

    items = (
        db.query(RequestPenawaranItem)
        .filter(
            RequestPenawaranItem.request_penawaran_id == request_id
        )
        .order_by(RequestPenawaranItem.id.asc())
        .all()
    )

    nomor_revisi = (
        db.query(RevisiPenawaran)
        .filter(
            RevisiPenawaran.request_penawaran_id == request_id
        )
        .count()
        + 1
    )

    revisi = RevisiPenawaran(
        request_penawaran_id=request_id,
        nomor_revisi=nomor_revisi,
        alasan_revisi=alasan,
        jenis_revisi=data.jenis_revisi,
        status_revisi="DIMINTA",
        diminta_oleh=current_user.id,
    )
    db.add(revisi)
    db.flush()

    for item in items:
        # Simpan semua barang lama sebagai arsip.
        db.add(
            RevisiPenawaranArsipItem(
                revisi_penawaran_id=revisi.id,
                nama_barang=item.nama_barang,
                merk=item.merk,
                tkdn=item.tkdn,
                tkdn_persen=item.tkdn_persen,
                spesifikasi=item.spesifikasi,
                catatan_sales=item.catatan_sales,
                jumlah=item.jumlah,
                satuan=item.satuan,
                gambar_path=item.gambar_path,
                link_marketplace=item.link_marketplace,
                jenis_pajak=item.jenis_pajak,
                harga_pagu=item.harga_pagu,
                harga_modal=item.harga_modal,
                harga_jual=item.harga_jual,
            )
        )

        # Revisi harga: salin barang lama ke daftar kerja.
        # Revisi total: jangan salin, supaya daftar kerja kosong.
        if data.jenis_revisi == "REVISI_HARGA_BARANG":
            db.add(
                RevisiPenawaranItem(
                    revisi_penawaran_id=revisi.id,
                    nama_barang=item.nama_barang,
                    merk=item.merk,
                    tkdn=item.tkdn,
                    tkdn_persen=item.tkdn_persen,
                    spesifikasi=item.spesifikasi,
                    catatan_sales=item.catatan_sales,
                    jumlah=item.jumlah,
                    satuan=item.satuan,
                    gambar_path=item.gambar_path,
                    link_marketplace=item.link_marketplace,
                    jenis_pajak=item.jenis_pajak,
                    harga_pagu=item.harga_pagu,
                    harga_modal=item.harga_modal,
                    harga_jual=item.harga_jual,
                )
            )

    if data.jenis_revisi == "REVISI_TOTAL":
        for item in items:
            db.delete(item)

    request.status_request = "REVISI"

    try:
        db.commit()
        db.refresh(revisi)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Gagal menyimpan permintaan revisi",
        )

    return {
        "message": "Permintaan revisi berhasil dibuat",
        "request_penawaran_id": request_id,
        "revisi_id": revisi.id,
        "nomor_revisi": revisi.nomor_revisi,
        "jenis_revisi": revisi.jenis_revisi,
        "alasan_revisi": revisi.alasan_revisi,
        "status_revisi": revisi.status_revisi,
    }


@router.get("/{request_id}/revisi/{revisi_id}")
def detail_revisi_penawaran(
    request_id: int,
    revisi_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    revisi = (
        db.query(RevisiPenawaran)
        .filter(
            RevisiPenawaran.id == revisi_id,
            RevisiPenawaran.request_penawaran_id == request_id,
        )
        .first()
    )
    if not revisi:
        raise HTTPException(
            status_code=404,
            detail="Revisi penawaran tidak ditemukan",
        )
    get_request_access(
        db=db,
        request_id=request_id,
        user=current_user,
    )
    items = (
        db.query(RevisiPenawaranItem)
        .filter(
            RevisiPenawaranItem.revisi_penawaran_id == revisi.id
        )
        .order_by(RevisiPenawaranItem.id.asc())
        .all()
    )
    return {
        "id": revisi.id,
        "request_penawaran_id": revisi.request_penawaran_id,
        "nomor_revisi": revisi.nomor_revisi,
        "alasan_revisi": revisi.alasan_revisi,
        "catatan_sales": revisi.catatan_sales,
        "status_revisi": revisi.status_revisi,
        "tanggal_diminta": revisi.tanggal_diminta,
        "items": [
            {
                "id": item.id,
                "nama_barang": item.nama_barang,
                "merk": item.merk,
                "tkdn": item.tkdn,
                "tkdn_persen": item.tkdn_persen,
                "spesifikasi": item.spesifikasi,
                "catatan_sales": item.catatan_sales,
                "jumlah": item.jumlah,
                "satuan": item.satuan,
                "gambar_path": item.gambar_path,
                "link_marketplace": item.link_marketplace,
                "jenis_pajak": item.jenis_pajak,
                "harga_pagu": item.harga_pagu,
                "harga_modal": item.harga_modal,
                "harga_jual": item.harga_jual,
            }
            for item in items
        ],
    }



@router.put("/{request_id}/revisi/{revisi_id}")
def update_revisi_penawaran(
    request_id: int,
    revisi_id: int,
    data: RevisiPenawaranUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "SALES":
        raise HTTPException(
            status_code=403,
            detail="Hanya Sales yang dapat mengedit revisi",
        )

    revisi = (
        db.query(RevisiPenawaran)
        .filter(
            RevisiPenawaran.id == revisi_id,
            RevisiPenawaran.request_penawaran_id == request_id,
        )
        .first()
    )

    if not revisi:
        raise HTTPException(
            status_code=404,
            detail="Revisi penawaran tidak ditemukan",
        )

    if revisi.status_revisi != "DIMINTA":
        raise HTTPException(
            status_code=400,
            detail="Revisi ini tidak sedang menunggu perbaikan Sales",
        )

    get_request_access(
        db=db,
        request_id=request_id,
        user=current_user,
        write=True,
    )

    try:
        revisi.catatan_sales = data.catatan_sales

        items = (
            db.query(RevisiPenawaranItem)
            .filter(
                RevisiPenawaranItem.revisi_penawaran_id == revisi.id
            )
            .all()
        )
        item_map = {item.id: item for item in items}

        submitted_ids = [
            item.id for item in data.items if item.id is not None
        ]

        # Tolak ID duplikat atau ID yang bukan milik revisi ini
        if len(submitted_ids) != len(set(submitted_ids)):
            raise HTTPException(
                status_code=422,
                detail="ID item tidak boleh duplikat",
            )

        if not set(submitted_ids).issubset(item_map.keys()):
            raise HTTPException(
                status_code=400,
                detail="Terdapat ID barang yang tidak valid",
            )

        if revisi.jenis_revisi == "REVISI_HARGA_BARANG":
            # Revisi harga mempertahankan semua item.
            # Item baru dan penghapusan item tidak diperbolehkan.
            if (
                any(item.id is None for item in data.items)
                or set(submitted_ids) != set(item_map.keys())
            ):
                raise HTTPException(
                    status_code=400,
                    detail=(
                        "Revisi harga harus mempertahankan "
                        "semua item RAB yang tersedia"
                    ),
                )

        elif revisi.jenis_revisi == "REVISI_TOTAL":
            # Hapus item revisi yang tidak lagi dikirim Sales.
            keep_ids = set(submitted_ids)

            for item_id, item in item_map.items():
                if item_id not in keep_ids:
                    db.delete(item)

        else:
            raise HTTPException(
                status_code=400,
                detail="Jenis revisi tidak valid",
            )

        # Update item lama atau tambahkan item baru.
        for item_data in data.items:
            values = item_data.model_dump(exclude={"id"})

            # Pastikan URL tersimpan sebagai string.
            if values["link_marketplace"] is not None:
                values["link_marketplace"] = str(
                    values["link_marketplace"]
                )

            if item_data.id is not None:
                item = item_map[item_data.id]

                for field, value in values.items():
                    setattr(item, field, value)

            else:
                if revisi.jenis_revisi != "REVISI_TOTAL":
                    raise HTTPException(
                        status_code=400,
                        detail="Item baru hanya diperbolehkan pada revisi total",
                    )

                db.add(
                    RevisiPenawaranItem(
                        revisi_penawaran_id=revisi.id,
                        **values,
                    )
                )

        db.commit()
        db.refresh(revisi)

    except HTTPException:
        db.rollback()
        raise
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Gagal menyimpan perubahan revisi",
        )

    return {
        "message": "Perubahan revisi berhasil disimpan",
        "revisi_id": revisi.id,
        "jenis_revisi": revisi.jenis_revisi,
        "status_revisi": revisi.status_revisi,
    }


@router.post("/{request_id}/revisi/{revisi_id}/submit")
def submit_revisi_penawaran(
    request_id: int,
    revisi_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "SALES":
        raise HTTPException(
            status_code=403,
            detail="Hanya Sales yang dapat mengirim revisi",
        )
    request = get_request_access(
        db=db,
        request_id=request_id,
        user=current_user,
        write=True,
    )
    revisi = (
        db.query(RevisiPenawaran)
        .filter(
            RevisiPenawaran.id == revisi_id,
            RevisiPenawaran.request_penawaran_id == request.id,
        )
        .first()
    )
    if not revisi:
        raise HTTPException(
            status_code=404,
            detail="Revisi penawaran tidak ditemukan",
        )
    if revisi.status_revisi != "DIMINTA":
        raise HTTPException(
            status_code=400,
            detail="Revisi ini tidak dapat dikirim",
        )

    revisi.status_revisi = "DIKIRIM"
    revisi.dikirim_oleh = current_user.id
    revisi.tanggal_dikirim = datetime.now(timezone.utc)

    try:
        db.commit()
        db.refresh(revisi)
    except SQLAlchemyError:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Gagal mengirim revisi penawaran",
        )
    return {
        "message": "Revisi penawaran berhasil dikirim ke SPV",
        "revisi_id": revisi.id,
        "status_revisi": revisi.status_revisi,
    }




@router.post("/{request_id}/revisi/{revisi_id}/approve")
def approve_revisi_penawaran(
    request_id: int,
    revisi_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "SPV":
        raise HTTPException(
            status_code=403,
            detail="Hanya SPV yang dapat menyetujui revisi",
        )

    request = get_request_access(
        db=db,
        request_id=request_id,
        user=current_user,
        write=True,
    )

    revisi = (
        db.query(RevisiPenawaran)
        .filter(
            RevisiPenawaran.id == revisi_id,
            RevisiPenawaran.request_penawaran_id == request.id,
        )
        .first()
    )

    if not revisi:
        raise HTTPException(
            status_code=404,
            detail="Revisi penawaran tidak ditemukan",
        )

    if revisi.status_revisi != "DIKIRIM":
        raise HTTPException(
            status_code=400,
            detail="Hanya revisi yang sudah dikirim Sales yang dapat disetujui",
        )

    revisi_items = (
        db.query(RevisiPenawaranItem)
        .filter(
            RevisiPenawaranItem.revisi_penawaran_id == revisi.id
        )
        .order_by(RevisiPenawaranItem.id.asc())
        .all()
    )

    if not revisi_items:
        raise HTTPException(
            status_code=400,
            detail="Daftar item revisi masih kosong",
        )

    request_items = (
        db.query(RequestPenawaranItem)
        .filter(
            RequestPenawaranItem.request_penawaran_id == request.id
        )
        .order_by(RequestPenawaranItem.id.asc())
        .all()
    )

    fields_to_sync = [
        "nama_barang",
        "merk",
        "tkdn",
        "tkdn_persen",
        "spesifikasi",
        "catatan_sales",
        "jumlah",
        "satuan",
        "gambar_path",
        "link_marketplace",
        "jenis_pajak",
        "harga_pagu",
        "harga_modal",
        "harga_jual",
    ]

    try:
        if revisi.jenis_revisi == "REVISI_TOTAL":
            # Kosongkan RAB aktif, lalu buat ulang dari hasil revisi.
            for item in request_items:
                db.delete(item)

            db.flush()

            for item_revisi in revisi_items:
                item_baru = RequestPenawaranItem(
                    request_penawaran_id=request.id,
                    **{
                        field: getattr(item_revisi, field)
                        for field in fields_to_sync
                    },
                )
                db.add(item_baru)

        elif revisi.jenis_revisi == "REVISI_HARGA_BARANG":
            # Revisi harga tidak boleh menambah atau menghapus barang.
            if len(revisi_items) != len(request_items):
                raise HTTPException(
                    status_code=409,
                    detail=(
                        "Jumlah item revisi berbeda dengan RAB utama. "
                        "Periksa item sebelum menyetujui."
                    ),
                )

            for item_revisi, item_request in zip(
                revisi_items, request_items
            ):
                for field in fields_to_sync:
                    setattr(
                        item_request,
                        field,
                        getattr(item_revisi, field),
                    )

        else:
            raise HTTPException(
                status_code=400,
                detail="Jenis revisi tidak dikenal",
            )

        revisi.status_revisi = "SELESAI"
        revisi.disetujui_oleh = current_user.id
        revisi.tanggal_disetujui = datetime.now(timezone.utc)

        # Perbarui status kelengkapan harga RAB utama.
        db.flush()
        refresh_request_completion(db, request)

        hitung_ulang_total(db, request)
        db.commit()
        db.refresh(revisi)

    except HTTPException:
        db.rollback()
        raise
    except SQLAlchemyError:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Gagal menyetujui revisi penawaran",
        )

    return {
        "message": "Revisi penawaran berhasil disetujui",
        "revisi_id": revisi.id,
        "jenis_revisi": revisi.jenis_revisi,
        "status_revisi": revisi.status_revisi,
    }

@router.get("/{request_id}/revisi")
def get_riwayat_revisi_penawaran(
    request_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    request = get_request_access(
        db=db,
        request_id=request_id,
        user=current_user,
    )
    revisi_list = (
        db.query(RevisiPenawaran)
        .filter(
            RevisiPenawaran.request_penawaran_id == request.id
        )
        .order_by(RevisiPenawaran.nomor_revisi.asc())
        .all()
    )
    revisi_dikirim = sum(
        1
        for revisi in revisi_list
        if revisi.status_revisi in ("DIKIRIM", "SELESAI", "DITOLAK")
    )
    return {
        "request_penawaran_id": request.id,
        "total_revisi_dikirim": revisi_dikirim,
        "total_riwayat": len(revisi_list),
        "riwayat": [
            {
                "id": revisi.id,
                "nomor_revisi": revisi.nomor_revisi,
                "alasan_revisi": revisi.alasan_revisi,
                "catatan_sales": revisi.catatan_sales,
                "status_revisi": revisi.status_revisi,
                "diminta_oleh": revisi.diminta_oleh,
                "dikirim_oleh": revisi.dikirim_oleh,
                "disetujui_oleh": revisi.disetujui_oleh,
                "tanggal_diminta": revisi.tanggal_diminta,
                "tanggal_dikirim": revisi.tanggal_dikirim,
                "tanggal_disetujui": revisi.tanggal_disetujui,
                "items": [
                    {
                        "id": item.id,
                        "nama_barang": item.nama_barang,
                        "merk": item.merk,
                        "spesifikasi": item.spesifikasi,
                        "jumlah": item.jumlah,
                        "satuan": item.satuan,
                        "gambar_path": item.gambar_path,
                        "link_marketplace": item.link_marketplace,
                        "jenis_pajak": item.jenis_pajak,
                        "harga_pagu": item.harga_pagu,
                        "harga_modal": item.harga_modal,
                        "harga_jual": item.harga_jual,
                        "catatan_sales": item.catatan_sales,
                    }
                    for item in (
                        db.query(RevisiPenawaranItem)
                        .filter(
                            RevisiPenawaranItem.revisi_penawaran_id
                            == revisi.id
                        )
                        .all()
                    )
                ],
            }
            for revisi in revisi_list
        ],
    }

@router.post("/{request_id}/items/{item_id}/gambar")
def upload_gambar_item(
    request_id: int,
    item_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    request = get_request_access(
        db, request_id, user, write=True
    )

    item = (
        db.query(RequestPenawaranItem)
        .filter(
            RequestPenawaranItem.id == item_id,
            RequestPenawaranItem.request_penawaran_id == request.id,
        )
        .first()
    )

    if not item:
        raise HTTPException(404, "Item tidak ditemukan")

    if user.role == "SALES" and item.is_tambahan:
        raise HTTPException(
            403,
            "Sales tidak dapat mengubah barang tambahan dari PPIC",
        )

    extension = ALLOWED_IMAGE_TYPES.get(file.content_type)

    if not extension:
        raise HTTPException(
            status_code=400,
            detail="Format gambar harus JPG, PNG, atau WebP",
        )

    try:
        content = file.file.read(MAX_IMAGE_SIZE + 1)

        if not content:
            raise HTTPException(400, "File gambar kosong")

        if len(content) > MAX_IMAGE_SIZE:
            raise HTTPException(
                status_code=413,
                detail="Ukuran gambar maksimal 5 MB",
            )

        filename = f"{uuid4().hex}{extension}"
        destination = UPLOAD_DIR / filename

        with destination.open("wb") as image_file:
            image_file.write(content)

        old_path = item.gambar_path
        item.gambar_path = str(destination).replace("\\", "/")

        try:
            db.commit()
            db.refresh(item)
        except Exception:
            db.rollback()
            destination.unlink(missing_ok=True)
            raise

        if old_path:
            old_file = Path(old_path)
            if old_file.is_file() and UPLOAD_DIR.resolve() in old_file.resolve().parents:
                old_file.unlink(missing_ok=True)

        return {
            "message": "Gambar produk berhasil diunggah",
            "item_id": item.id,
            "gambar_path": item.gambar_path,
        }

    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Gagal mengunggah gambar produk",
        )
    finally:
        file.file.close()

class MarketplaceLinkUpdate(BaseModel):
    link_marketplace: HttpUrl | None = None


@router.patch("/{request_id}/items/{item_id}/marketplace")
def update_link_marketplace(
    request_id: int,
    item_id: int,
    data: MarketplaceLinkUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    request = get_request_access(
        db, request_id, user, write=True
    )

    item = (
        db.query(RequestPenawaranItem)
        .filter(
            RequestPenawaranItem.id == item_id,
            RequestPenawaranItem.request_penawaran_id == request.id,
        )
        .first()
    )

    if not item:
        raise HTTPException(404, "Item tidak ditemukan")

    # PPIC hanya boleh mengubah link pada barang tambahan miliknya; Sales tidak pada barang tambahan.
    if user.role == "PPIC" and not item.is_tambahan:
        raise HTTPException(
            403,
            "PPIC tidak dapat mengubah link marketplace barang dari Sales",
        )
    if user.role == "SALES" and item.is_tambahan:
        raise HTTPException(
            403,
            "Sales tidak dapat mengubah barang tambahan dari PPIC",
        )

    item.link_marketplace = (
        str(data.link_marketplace)
        if data.link_marketplace is not None
        else None
    )

    try:
        db.commit()
        db.refresh(item)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Gagal menyimpan link marketplace",
        )

    return {
        "message": "Link marketplace berhasil diperbarui",
        "item_id": item.id,
        "link_marketplace": item.link_marketplace,
    }