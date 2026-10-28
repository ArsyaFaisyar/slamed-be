import os
import uuid
from io import BytesIO
from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, Query, Response, UploadFile, File, Form
from sqlalchemy.orm import Session
from fastapi.responses import StreamingResponse
from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter


from app.db.database import get_db
from app.models.rkh import RKH
from app.models.lkh import LKH
from app.models.user import User
from app.models.customer import Customer
from app.models.project_prospek import ProjectProspek
from app.models.project_status_history import ProjectStatusHistory
from app.models.project_status import ProjectStatus
from app.schemas.lkh import LKHCreate, LKHUpdate, LKHResponse,LKHExportSchema
from app.core.dependencies import get_current_user, require_roles
from app.utils.project_log import catat_project_log
from app.core.roles import LKH_VIEW_ROLES
from datetime import date, datetime, timezone
from zoneinfo import ZoneInfo

router = APIRouter(prefix="/lkh", tags=["LKH"])

WIB = ZoneInfo("Asia/Jakarta")

STATUS_LKH_LABELS = {
    "NOT_YET": "Open",
    "DONE": "Done",
}

STATUS_LKH_STYLES = {
    "NOT_YET": ("FFF2CC", "7F6000"),
    "DONE": ("E2EFDA", "375623"),
}


def to_wib(value):
    if value is None:
        return None
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(WIB).replace(tzinfo=None)


def clean_values(values):
    return [item.strip() for item in (values or []) if item and item.strip()]


def build_lkh_workbook(rows, filter_text, exported_by, exported_at):
    headers = [
        ("No", 6),
        ("Tanggal Kunjungan", 18),
        ("Sales", 20),
        ("Customer", 28),
        ("Project", 28),
        ("Kegiatan", 28),
        ("Nama PIC", 20),
        ("Nomor PIC", 17),
        ("Hasil Kunjungan", 44),
        ("Tindak Lanjut", 34),
        ("Tanggal Follow Up", 18),
        ("Status LKH", 14),
        ("Latitude", 14),
        ("Longitude", 14),
        ("Dibuat Pada", 19),
        ("Diperbarui Pada", 19),
    ]
    last_col = len(headers)
    last_letter = get_column_letter(last_col)
    header_row = 5

    workbook = Workbook()
    sheet = workbook.active
    sheet.title = "Data LKH"
    sheet.sheet_view.showGridLines = False

    thin = Side(style="thin", color="BFBFBF")
    border = Border(left=thin, right=thin, top=thin, bottom=thin)

    sheet.merge_cells(start_row=1, start_column=1, end_row=1, end_column=last_col)
    sheet["A1"] = "DATA LAPORAN KEGIATAN HARIAN (LKH)"
    sheet["A1"].font = Font(bold=True, size=16, color="1F4E78")
    sheet["A1"].alignment = Alignment(horizontal="left", vertical="center")
    sheet.row_dimensions[1].height = 26

    sheet.merge_cells(start_row=2, start_column=1, end_row=2, end_column=last_col)
    sheet["A2"] = f"Filter: {filter_text}"
    sheet.merge_cells(start_row=3, start_column=1, end_row=3, end_column=last_col)
    sheet["A3"] = (
        f"Diekspor oleh {exported_by} pada "
        f"{exported_at.strftime('%d-%m-%Y %H:%M')} WIB"
    )
    for ref in ("A2", "A3"):
        sheet[ref].font = Font(size=10, color="595959")
        sheet[ref].alignment = Alignment(horizontal="left", vertical="center")

    for index, (title, width) in enumerate(headers, start=1):
        cell = sheet.cell(row=header_row, column=index, value=title)
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = PatternFill(fill_type="solid", fgColor="1F4E78")
        cell.alignment = Alignment(
            horizontal="center", vertical="center", wrap_text=True
        )
        cell.border = border
        sheet.column_dimensions[get_column_letter(index)].width = width
    sheet.row_dimensions[header_row].height = 24

    zebra = PatternFill(fill_type="solid", fgColor="F2F7FB")

    for number, item in enumerate(rows, start=1):
        row = header_row + number
        lkh = item["lkh"]
        status = lkh.status_lkh
        values = [
            number,
            lkh.tanggal_kunjungan,
            item["sales"],
            item["customer"],
            item["project"],
            item["kegiatan"],
            lkh.nama_pic,
            str(lkh.nomor_pic) if lkh.nomor_pic is not None else None,
            lkh.hasil_kunjungan,
            lkh.tindak_lanjut,
            lkh.tanggal_follow_up,
            STATUS_LKH_LABELS.get(status, status),
            float(lkh.latitude) if lkh.latitude is not None else None,
            float(lkh.longitude) if lkh.longitude is not None else None,
            to_wib(lkh.created_at),
            to_wib(lkh.updated_at),
        ]

        for col, value in enumerate(values, start=1):
            cell = sheet.cell(row=row, column=col, value=value)
            cell.border = border
            cell.alignment = Alignment(vertical="top", wrap_text=True)
            if number % 2 == 0:
                cell.fill = zebra

        center = Alignment(horizontal="center", vertical="top")
        sheet.cell(row=row, column=1).alignment = center
        for col in (2, 11):
            sheet.cell(row=row, column=col).number_format = "dd-mm-yyyy"
            sheet.cell(row=row, column=col).alignment = center
        sheet.cell(row=row, column=8).number_format = "@"
        for col in (13, 14):
            sheet.cell(row=row, column=col).number_format = "0.000000"
        for col in (15, 16):
            sheet.cell(row=row, column=col).number_format = "dd-mm-yyyy hh:mm"
            sheet.cell(row=row, column=col).alignment = center

        status_cell = sheet.cell(row=row, column=12)
        status_cell.alignment = center
        if status in STATUS_LKH_STYLES:
            fill_color, font_color = STATUS_LKH_STYLES[status]
            status_cell.fill = PatternFill(fill_type="solid", fgColor=fill_color)
            status_cell.font = Font(bold=True, color=font_color)

    last_data_row = header_row + len(rows)
    total_cell = sheet.cell(
        row=last_data_row + 2, column=1, value=f"Total: {len(rows)} laporan"
    )
    total_cell.font = Font(bold=True)

    sheet.freeze_panes = f"C{header_row + 1}"
    sheet.auto_filter.ref = (
        f"A{header_row}:{last_letter}{max(last_data_row, header_row)}"
    )

    sheet.page_setup.orientation = "landscape"
    sheet.page_setup.fitToWidth = 1
    sheet.page_setup.fitToHeight = 0
    sheet.sheet_properties.pageSetUpPr.fitToPage = True
    sheet.print_title_rows = f"{header_row}:{header_row}"

    return workbook


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
    status_lkh: list[str] | None = Query(None),
    tanggal_mulai: date | None = None,
    tanggal_selesai: date | None = None,
    nama_pic: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = get_lkh_query(db, current_user)

    statuses = [item.upper() for item in clean_values(status_lkh)]
    for item in statuses:
        if item not in STATUS_LKH_LABELS:
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

    if statuses:
        query = query.filter(LKH.status_lkh.in_(statuses))

    if tanggal_mulai is not None:
        query = query.filter(LKH.tanggal_kunjungan >= tanggal_mulai)

    if tanggal_selesai is not None:
        query = query.filter(LKH.tanggal_kunjungan <= tanggal_selesai)

    pic = nama_pic.strip() if nama_pic else ""
    if pic:
        query = query.filter(LKH.nama_pic.ilike(f"%{pic}%"))

    data_lkh = query.order_by(LKH.tanggal_kunjungan.desc(), LKH.id.desc()).all()

    rkh_map = {}
    customer_map = {}
    project_map = {}
    user_map = {}

    if data_lkh:
        rkh_map = {
            item.id: item
            for item in db.query(RKH).filter(
                RKH.id.in_({lkh.rkh_id for lkh in data_lkh})
            ).all()
        }
        customer_ids = {rkh.customer_id for rkh in rkh_map.values() if rkh.customer_id}
        project_ids = {rkh.project_id for rkh in rkh_map.values() if rkh.project_id}
        sales_ids = {lkh.sales_id for lkh in data_lkh if lkh.sales_id}

        if customer_ids:
            customer_map = {
                item.id: item.nama_instansi
                for item in db.query(Customer).filter(Customer.id.in_(customer_ids)).all()
            }
        if project_ids:
            project_map = {
                item.id: item.nama_project
                for item in db.query(ProjectProspek).filter(ProjectProspek.id.in_(project_ids)).all()
            }
        if sales_ids:
            user_map = {
                item.id: item.nama
                for item in db.query(User).filter(User.id.in_(sales_ids)).all()
            }

    rows = []
    for lkh in data_lkh:
        rkh = rkh_map.get(lkh.rkh_id)
        rows.append(
            {
                "lkh": lkh,
                "sales": user_map.get(lkh.sales_id),
                "customer": customer_map.get(rkh.customer_id) if rkh else None,
                "project": project_map.get(rkh.project_id) if rkh else None,
                "kegiatan": rkh.judul_kegiatan if rkh else None,
            }
        )

    if tanggal_mulai or tanggal_selesai:
        mulai_text = tanggal_mulai.strftime("%d-%m-%Y") if tanggal_mulai else "..."
        selesai_text = tanggal_selesai.strftime("%d-%m-%Y") if tanggal_selesai else "..."
        periode_text = f"{mulai_text} s/d {selesai_text}"
    else:
        periode_text = "Semua"

    status_text = (
        ", ".join(STATUS_LKH_LABELS[item] for item in statuses)
        if statuses
        else "Semua"
    )
    filter_text = (
        f"Status: {status_text} | "
        f"Nama PIC: {pic or 'Semua'} | "
        f"Periode kunjungan: {periode_text}"
    )

    now = datetime.now(WIB)
    workbook = build_lkh_workbook(rows, filter_text, current_user.nama, now)

    output = BytesIO()
    workbook.save(output)
    output.seek(0)

    filename = f"Data_LKH_{now.strftime('%d-%m-%Y_%H%M')}.xlsx"

    return StreamingResponse(
        output,
        media_type=(
            "application/vnd.openxmlformats-officedocument."
            "spreadsheetml.sheet"
        ),
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"'
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