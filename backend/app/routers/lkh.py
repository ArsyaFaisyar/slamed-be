import os
import uuid
from io import BytesIO
from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, Response, UploadFile, File, Form
from sqlalchemy.orm import Session
from fastapi.responses import StreamingResponse
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.utils import get_column_letter


from app.db.database import get_db
from app.models.rkh import RKH
from app.models.lkh import LKH
from app.models.user import User
from app.models.project_prospek import ProjectProspek
from app.models.project_status_history import ProjectStatusHistory
from app.models.project_status import ProjectStatus
from app.schemas.lkh import LKHCreate, LKHUpdate, LKHResponse,LKHExportSchema
from app.core.dependencies import get_current_user, require_roles
from app.utils.project_log import catat_project_log
from app.core.roles import LKH_VIEW_ROLES
from datetime import date

router = APIRouter(prefix="/lkh", tags=["LKH"])

def get_lkh_query(db: Session, current_user: User):
    query = db.query(LKH)

    if current_user.role == "SALES":
        query = query.filter(LKH.sales_id == current_user.id)
    elif current_user.role not in LKH_VIEW_ROLES:
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




@router.get("/export/excel")
def export_lkh_excel(
    status_lkh: str | None = None,
    tanggal_mulai: date | None = None,
    tanggal_selesai: date | None = None,
    nama_pic: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = get_lkh_query(db, current_user)

    # Validasi filter
    if status_lkh is not None:
        status_lkh = status_lkh.upper()
        if status_lkh not in ("DONE", "NOT_YET"):
            raise HTTPException(
                status_code=400,
                detail="Status harus DONE atau NOT_YET",
            )

    if (
        tanggal_mulai is not None
        and tanggal_selesai is not None
        and tanggal_mulai > tanggal_selesai
    ):
        raise HTTPException(
            status_code=400,
            detail="Tanggal mulai tidak boleh melebihi tanggal selesai",
        )

    # Filter berdasarkan RKH

    # Filter berdasarkan status
    if status_lkh is not None:
        query = query.filter(LKH.status_lkh == status_lkh)

    # Filter berdasarkan tanggal kunjungan
    if tanggal_mulai is not None:
        query = query.filter(
            LKH.tanggal_kunjungan >= tanggal_mulai
        )

    if tanggal_selesai is not None:
        query = query.filter(
            LKH.tanggal_kunjungan <= tanggal_selesai
        )

    # Filter berdasarkan nama PIC
    if nama_pic and nama_pic.strip():
        query = query.filter(
            LKH.nama_pic.ilike(f"%{nama_pic.strip()}%")
        )

    data_lkh = query.order_by(LKH.id.desc()).all()

    # Buat workbook Excel
    workbook = Workbook()
    worksheet = workbook.active
    worksheet.title = "Data LKH"

    headers = [
        "Tanggal Kunjungan",
        "Tanggal Follow Up",
        "Hasil Kunjungan",
        "Status LKH",
        "Tindak Lanjut",
        "Nama PIC",
        "Nomor PIC",
        "Latitude",
        "Longitude",
        "Dibuat Pada",
        "Diperbarui Pada",
    ]

    worksheet.append(headers)

    # Styling header
    for cell in worksheet[1]:
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = PatternFill(
            fill_type="solid",
            fgColor="1565C0",
        )
        cell.alignment = Alignment(
            horizontal="center",
            vertical="center",
        )

    # Isi data hasil filter
    for item in data_lkh:
        worksheet.append([
            item.tanggal_kunjungan,
            item.tanggal_follow_up,
            item.hasil_kunjungan,
            item.status_lkh,
            item.tindak_lanjut,
            item.nama_pic,
            item.nomor_pic,
            float(item.latitude)
            if item.latitude is not None else None,
            float(item.longitude)
            if item.longitude is not None else None,
            item.created_at.replace(tzinfo=None)
            if item.created_at else None,
            item.updated_at.replace(tzinfo=None)
            if item.updated_at else None,
        ])

    # Atur lebar kolom
    for column_cells in worksheet.columns:
        column_letter = get_column_letter(
            column_cells[0].column
        )

        max_length = max(
            (
                len(str(cell.value))
                if cell.value is not None else 0
            )
            for cell in column_cells
        )

        worksheet.column_dimensions[column_letter].width = min(
            max(max_length + 2, 15),
            40,
        )

    worksheet.freeze_panes = "A2"
    worksheet.auto_filter.ref = worksheet.dimensions

    for row in worksheet.iter_rows(min_row=2):
        for cell in row:
            cell.alignment = Alignment(
                vertical="top",
                wrap_text=True,
            )

    # Simpan Excel ke memory
    output = BytesIO()
    workbook.save(output)
    output.seek(0)

    return StreamingResponse(
        output,
        media_type=(
            "application/vnd.openxmlformats-officedocument."
            "spreadsheetml.sheet"
        ),
        headers={
            "Content-Disposition": 'attachment; filename="data_lkh.xlsx"'
        },
    )

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
        db.flush()
        project = (
            db.query(ProjectProspek)
            .filter(ProjectProspek.id == rkh.project_id)
            .first()
        )
        if project:
            catat_project_log(
                db=db,
                project_id=project.id,
                user_id=current_user.id,
                aktivitas="Laporan kunjungan dibuat",
                deskripsi=(
                    f"Laporan kunjungan untuk RKH tanggal "
                    f"{rkh.tanggal_rencana} telah dibuat."
                ),
            )
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
        require_roles("SUPERADMIN", "SPV", "SALES", "PPIC")
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