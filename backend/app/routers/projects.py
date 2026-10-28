from fastapi import APIRouter, Depends, HTTPException, Response
from decimal import Decimal
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func, case
from io import BytesIO
from datetime import datetime, date, time, timedelta

from fastapi.responses import StreamingResponse
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.utils import get_column_letter

from app.db.database import get_db
from app.models.customer import Customer
from app.models.project_prospek import ProjectProspek
from app.models.project_status import ProjectStatus
from app.models.project_status_history import ProjectStatusHistory
from app.models.user import User
from app.schemas.project_prospek import (
    ProjectProspekCreate,
    ProjectProspekUpdate,
    ProjectProspekResponse,
)
from app.models.rkh import RKH
from app.models.lkh import LKH
from app.models.request_penawaran import RequestPenawaran
from app.models.request_penawaran_item import RequestPenawaranItem
from app.schemas.project_dashboard import ProjectDashboardSummary
from app.core.dependencies import get_current_user, require_roles
from app.utils.project_log import catat_project_log
from app.core.roles import PROJECT_VIEW_ROLES

router = APIRouter(prefix="/projects", tags=["Projects"])

PIPELINE_PROSPEK = "Prospek"
PIPELINE_HOT = "Hot Prospek"
PIPELINE_VALUES = (PIPELINE_PROSPEK, PIPELINE_HOT)

HOT_PROSPEK_STATUS_NAMES = {"req penawaran", "request penawaran"}


def get_project_query(db: Session, current_user: User):
    query = db.query(ProjectProspek).options(
        joinedload(ProjectProspek.status_rel),
        joinedload(ProjectProspek.sales_rel),
    )

    if current_user.role == "SALES":
        query = query.filter(
            ProjectProspek.sales_id == current_user.id
        )
    elif current_user.role not in PROJECT_VIEW_ROLES:
        raise HTTPException(
            status_code=403,
            detail="Kamu tidak memiliki akses ke data proyek",
        )

    return query


@router.get("/", response_model=list[ProjectProspekResponse])
def get_projects(
    customer_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = get_project_query(db, current_user)

    if customer_id is not None:
        query = query.filter(
            ProjectProspek.customer_id == customer_id
        )

    return query.order_by(ProjectProspek.id.desc()).all()


@router.get(
    "/dashboard/summary",
    response_model=ProjectDashboardSummary,
)
def get_project_dashboard_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(ProjectProspek)

    if current_user.role == "SALES":
        query = query.filter(
            ProjectProspek.sales_id == current_user.id
        )
    elif current_user.role not in PROJECT_VIEW_ROLES:
        raise HTTPException(
            status_code=403,
            detail="Kamu tidak memiliki akses ke data proyek",
        )

    result = query.with_entities(
        func.count(ProjectProspek.id).label("jumlah_project"),
        func.coalesce(
            func.sum(ProjectProspek.nilai_proyek), 0
        ).label("total_nilai_project"),

        func.sum(
            case(
                (ProjectProspek.pipeline_status == PIPELINE_PROSPEK, 1),
                else_=0,
            )
        ).label("jumlah_prospek"),

        func.sum(
            case(
                (ProjectProspek.pipeline_status == PIPELINE_HOT, 1),
                else_=0,
            )
        ).label("jumlah_hot_prospek"),

        func.coalesce(
            func.sum(
                case(
                    (
                        ProjectProspek.pipeline_status == PIPELINE_PROSPEK,
                        ProjectProspek.nilai_proyek,
                    ),
                    else_=0,
                )
            ),
            0,
        ).label("nilai_prospek"),

        func.coalesce(
            func.sum(
                case(
                    (
                        ProjectProspek.pipeline_status == PIPELINE_HOT,
                        ProjectProspek.nilai_proyek,
                    ),
                    else_=0,
                )
            ),
            0,
        ).label("nilai_hot_prospek"),
    ).one()

    return {
        "jumlah_project": result.jumlah_project,
        "total_nilai_project": result.total_nilai_project,
        "jumlah_prospek": result.jumlah_prospek or 0,
        "jumlah_hot_prospek": result.jumlah_hot_prospek or 0,
        "nilai_prospek": result.nilai_prospek,
        "nilai_hot_prospek": result.nilai_hot_prospek,
    }


@router.get("/{project_id}/rab")
def get_project_rab(
    project_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    project = get_project_query(
        db, current_user
    ).filter(
        ProjectProspek.id == project_id
    ).first()

    if not project:
        raise HTTPException(
            status_code=404,
            detail="Project tidak ditemukan atau kamu tidak memiliki akses",
        )
    requests = (
        db.query(RequestPenawaran)
        .join(LKH, LKH.id == RequestPenawaran.lkh_id)
        .join(RKH, RKH.id == LKH.rkh_id)
        .filter(RKH.project_id == project_id)
        .order_by(RequestPenawaran.id.desc())
        .all()
    )
    hasil = []
    for request in requests:
        items = (
            db.query(RequestPenawaranItem)
            .filter(
                RequestPenawaranItem.request_penawaran_id
                == request.id
            )
            .order_by(RequestPenawaranItem.id.asc())
            .all()
        )
        rincian = []
        total_pagu = Decimal("0")
        for item in items:
            subtotal = (
                item.jumlah * item.harga_pagu
                if item.harga_pagu is not None
                else None
            )
            if subtotal is not None:
                total_pagu += subtotal
            rincian.append({
                "id": item.id,
                "nama_barang": item.nama_barang,
                "spesifikasi": item.spesifikasi,
                "jumlah": item.jumlah,
                "satuan": item.satuan,
                "harga_pagu": item.harga_pagu,
                "subtotal": subtotal,
            })
        hasil.append({
            "request_penawaran_id": request.id,
            "tanggal_request": request.tanggal_request,
            "mode_pagu": request.mode_pagu,
            "total_pagu": (
                request.total_pagu
                if request.total_pagu is not None
                else total_pagu
            ),
            "items": rincian,
        })
    return {
        "project_id": project.id,
        "nama_project": project.nama_project,
        "jumlah_request_penawaran": len(hasil),
        "request_penawaran": hasil,
    }


@router.get("/{project_id}", response_model=ProjectProspekResponse)
def get_project(
    project_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    project = get_project_query(db, current_user).filter(
        ProjectProspek.id == project_id
    ).first()

    if not project:
        raise HTTPException(
            status_code=404,
            detail="Project tidak ditemukan atau kamu tidak memiliki akses",
        )
    return project


@router.post(
    "/",
    response_model=ProjectProspekResponse,
    status_code=201,
)
def create_project(
    data: ProjectProspekCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV")
    ),
):
    customer = db.query(Customer).filter(
        Customer.id == data.customer_id
    ).first()

    if not customer:
        raise HTTPException(
            status_code=404,
            detail="Customer tidak ditemukan",
        )
    if customer.approval_status != "APPROVED":
        raise HTTPException(
            status_code=400,
            detail="Customer belum disetujui, project tidak dapat dibuat",
        )

    sales = db.query(User).filter(
        User.id == data.sales_id,
        User.role == "SALES",
        User.is_active == 1,
    ).first()

    if not sales:
        raise HTTPException(
            status_code=404,
            detail="Sales tidak ditemukan atau tidak aktif",
        )

    initial_status = (
        db.query(ProjectStatus)
        .filter(ProjectStatus.is_active == True)
        .order_by(ProjectStatus.urutan.asc())
        .first()
    )

    if not initial_status:
        raise HTTPException(
            status_code=400,
            detail="Belum ada status project aktif",
        )

    project = ProjectProspek(
        customer_id=data.customer_id,
        nama_project=data.nama_project,
        deskripsi=data.deskripsi,
        nilai_proyek=data.nilai_proyek,
        estimasi_closing=data.estimasi_closing,
        sales_id=data.sales_id,
        status_id=initial_status.id,
    )

    db.add(project)
    db.flush()
    catat_project_log(
        db=db,
        project_id=project.id,
        user_id=current_user.id,
        aktivitas="Project dibuat",
        deskripsi=f"Project {project.nama_project} dibuat.",
    )
    db.commit()
    db.refresh(project)

    return get_project_query(db, current_user).filter(
        ProjectProspek.id == project.id
    ).first()


@router.patch(
    "/{project_id}",
    response_model=ProjectProspekResponse,
)
def update_project(
    project_id: int,
    data: ProjectProspekUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV", "SALES")
    ),
):
    project_query = db.query(ProjectProspek).filter(
        ProjectProspek.id == project_id
    )

    if current_user.role == "SALES":
        project_query = project_query.filter(
            ProjectProspek.sales_id == current_user.id
        )

    project = project_query.first()

    if not project:
        raise HTTPException(
            status_code=404,
            detail="Project tidak ditemukan atau kamu tidak memiliki akses",
        )

    updates = data.model_dump(exclude_unset=True)

    if current_user.role == "SALES":
        forbidden_fields = set(updates.keys()) - {"status_id"}
        if forbidden_fields:
            raise HTTPException(
                status_code=403,
                detail="Sales hanya dapat mengubah status project",
            )

    if "pipeline_status" in updates:
        if updates["pipeline_status"] not in PIPELINE_VALUES:
            raise HTTPException(
                status_code=400,
                detail="Pipeline status harus Prospek atau Hot Prospek",
            )

    if "customer_id" in updates:
        customer = db.query(Customer).filter(
            Customer.id == updates["customer_id"]
        ).first()

        if not customer:
            raise HTTPException(
                status_code=404,
                detail="Customer tidak ditemukan",
            )

        if customer.approval_status != "APPROVED":
            raise HTTPException(
                status_code=400,
                detail="Customer belum disetujui, project tidak dapat menggunakan customer ini",
            )

    if updates.get("sales_id") is not None:
        sales = db.query(User).filter(
            User.id == updates["sales_id"],
            User.role == "SALES",
            User.is_active == 1,
        ).first()

        if not sales:
            raise HTTPException(
                status_code=404,
                detail="Sales tidak ditemukan atau tidak aktif",
            )

    old_status_id = project.status_id

    new_status = None
    old_status = None

    if (
        "status_id" in updates
        and updates["status_id"] != old_status_id
    ):
        new_status = db.query(ProjectStatus).filter(
            ProjectStatus.id == updates["status_id"],
            ProjectStatus.is_active == True,
        ).first()

        if not new_status:
            raise HTTPException(
                status_code=400,
                detail="Status project tidak ditemukan atau tidak aktif",
            )

        if new_status.nama.strip().lower() in HOT_PROSPEK_STATUS_NAMES:
            updates["pipeline_status"] = PIPELINE_HOT

        if old_status_id is not None:
            old_status = db.query(ProjectStatus).filter(
                ProjectStatus.id == old_status_id
            ).first()

    labels = {
        "nama_project": "Nama project",
        "deskripsi": "Deskripsi",
        "nilai_proyek": "Nilai proyek",
        "estimasi_closing": "Estimasi closing",
        "sales_id": "Sales",
        "pipeline_status": "Pipeline status",
        "customer_id": "Customer",
    }

    perubahan = []

    for field, value in updates.items():
        old_value = getattr(project, field)

        if old_value != value:
            setattr(project, field, value)

            if field != "status_id":
                label = labels.get(field, field)
                perubahan.append(
                    f"{label}: {old_value} → {value}"
                )

    if (
        "status_id" in updates
        and project.status_id != old_status_id
    ):
        db.add(
            ProjectStatusHistory(
                project_id=project.id,
                old_status_id=old_status_id,
                new_status_id=project.status_id,
                changed_by=current_user.id,
                catatan="Status project diperbarui",
            )
        )

        catat_project_log(
            db=db,
            project_id=project.id,
            user_id=current_user.id,
            aktivitas="Status project berubah",
            deskripsi=(
                f"Status berubah dari "
                f"{old_status.nama if old_status else 'Belum ada status'} "
                f"menjadi {new_status.nama}."
            ),
        )

    if perubahan:
        catat_project_log(
            db=db,
            project_id=project.id,
            user_id=current_user.id,
            aktivitas="Project diperbarui",
            deskripsi="; ".join(perubahan),
        )

    db.commit()
    db.refresh(project)

    return get_project_query(db, current_user).filter(
        ProjectProspek.id == project_id
    ).first()


@router.delete("/{project_id}", status_code=204)
def delete_project(
    project_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV")
    ),
):
    project = db.query(ProjectProspek).filter(
        ProjectProspek.id == project_id
    ).first()

    if not project:
        raise HTTPException(
            status_code=404,
            detail="Project tidak ditemukan",
        )

    db.delete(project)
    db.commit()

    return Response(status_code=204)


@router.get("/export/excel")
def export_project_excel(
    sales: str | None = None,
    status: str | None = None,
    pipeline_status: str | None = None,
    tanggal_mulai: date | None = None,
    tanggal_selesai: date | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Validasi tanggal
    if tanggal_mulai and tanggal_selesai:
        if tanggal_mulai > tanggal_selesai:
            raise HTTPException(
                status_code=400,
                detail="Tanggal mulai tidak boleh melebihi tanggal selesai",
            )

    # Ambil query project sesuai hak akses user
    query = get_project_query(db, current_user).options(
        joinedload(ProjectProspek.sales_rel),
        joinedload(ProjectProspek.status_rel),
    )

    # Filter nama sales
    if sales and sales.strip():
        query = query.filter(
            ProjectProspek.sales_rel.has(
                User.nama.ilike(f"%{sales.strip()}%")
            )
        )

    # Filter nama status project
    if status and status.strip():
        query = query.filter(
            ProjectProspek.status_rel.has(
                ProjectStatus.nama.ilike(f"%{status.strip()}%")
            )
        )

    # Filter pipeline status
    if pipeline_status and pipeline_status.strip():
        query = query.filter(
            ProjectProspek.pipeline_status
            == pipeline_status.strip()
        )

    # Filter tanggal dibuat
    if tanggal_mulai:
        mulai = datetime.combine(tanggal_mulai, time.min)
        query = query.filter(
            ProjectProspek.created_at >= mulai
        )

    if tanggal_selesai:
        sampai = datetime.combine(
            tanggal_selesai + timedelta(days=1),
            time.min,
        )
        query = query.filter(
            ProjectProspek.created_at < sampai
        )

    projects = query.order_by(
        ProjectProspek.id.desc()
    ).all()

    # Ambil nama customer berdasarkan customer_id
    customer_ids = {
        project.customer_id for project in projects
    }

    customers = {}
    if customer_ids:
        data_customers = db.query(Customer).filter(
            Customer.id.in_(customer_ids)
        ).all()

        customers = {
            customer.id: customer
            for customer in data_customers
        }

    # Buat workbook
    workbook = Workbook()
    worksheet = workbook.active
    worksheet.title = "Data Project"

    headers = [
        "Nama Project",
        "Nama Customer",
        "Nama PIC",
        "Kontak PIC",
        "Kota",
        "Nama Sales",
        "Status Project",
        "Pipeline Status",
        "Nilai Proyek",
        "Estimasi Closing",
        "Deskripsi",
        "Tanggal Dibuat",
        "Terakhir Diperbarui",
    ]

    worksheet.append(headers)

    # Styling header
    for cell in worksheet[1]:
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = PatternFill(
            fill_type="solid",
            fgColor="1F4E78",
        )
        cell.alignment = Alignment(
            horizontal="center",
            vertical="center",
        )

    # Isi data project
    for project in projects:
        customer = customers.get(project.customer_id)

        worksheet.append([
            project.nama_project,
            customer.nama_instansi if customer else None,
            customer.nama_pic if customer else None,
            customer.kontak_pic if customer else None,
            customer.kota if customer else None,
            project.sales_rel.nama if project.sales_rel else None,
            project.status_rel.nama if project.status_rel else None,
            project.pipeline_status,
            (
                float(project.nilai_proyek)
                if project.nilai_proyek is not None
                else None
            ),
            project.estimasi_closing,
            project.deskripsi,
            (
                project.created_at.replace(tzinfo=None)
                if project.created_at else None
            ),
            (
                project.updated_at.replace(tzinfo=None)
                if project.updated_at else None
            ),
        ])

    # Format kolom nilai proyek dan tanggal
    for row in worksheet.iter_rows(min_row=2):
        row[9].number_format = '#,##0.00'  # Nilai Proyek
        row[10].number_format = "dd-mm-yyyy"  # Estimasi Closing
        row[12].number_format = "dd-mm-yyyy hh:mm:ss"  # Tanggal Dibuat

    if len(row) > 13:
        row[13].number_format = "dd-mm-yyyy hh:mm:ss"  # Terakhir Diperbarui

    # Atur lebar kolom
    for column_cells in worksheet.columns:
        max_length = max(
            len(str(cell.value or ""))
            for cell in column_cells
        )
        column_letter = get_column_letter(
            column_cells[0].column
        )
        worksheet.column_dimensions[
            column_letter
        ].width = min(max_length + 3, 40)

    worksheet.freeze_panes = "A2"
    worksheet.auto_filter.ref = worksheet.dimensions

    # Simpan Excel ke memory
    output = BytesIO()
    workbook.save(output)
    output.seek(0)

    filename = (
        f"data_project_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx"
    )

    return StreamingResponse(
        output,
        media_type=(
            "application/vnd.openxmlformats-officedocument."
            "spreadsheetml.sheet"
        ),
        headers={
            "Content-Disposition": (
                f'attachment; filename="{filename}"'
            )
        },
    )
