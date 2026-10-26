from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func, case
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
from app.schemas.project_dashboard import ProjectDashboardSummary
from app.core.dependencies import get_current_user, require_roles
from app.utils.project_log import catat_project_log
from app.core.roles import PROJECT_VIEW_ROLES

router = APIRouter(prefix="/projects", tags=["Projects"])

PIPELINE_PROSPEK = "Prospek"
PIPELINE_HOT = "Hot Prospek"
PIPELINE_VALUES = (PIPELINE_PROSPEK, PIPELINE_HOT)

# Saat status project berubah ke salah satu nama ini (tanpa membedakan huruf besar/kecil),
# pipeline otomatis menjadi Hot Prospek. Sesuaikan dengan nama di Master Status Project.
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

    updates = data.model_dump(exclude_unset=True)

    # Validasi pipeline status
    if "pipeline_status" in updates:
        if updates["pipeline_status"] not in PIPELINE_VALUES:
            raise HTTPException(
                status_code=400,
                detail="Pipeline status harus Prospek atau Hot Prospek",
            )

    # Validasi customer
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

    # Validasi sales
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

    # Validasi status project sebelum mengubah data
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

        # Status Req Penawaran otomatis menaikkan pipeline menjadi Hot Prospek.
        if new_status.nama.strip().lower() in HOT_PROSPEK_STATUS_NAMES:
            updates["pipeline_status"] = PIPELINE_HOT

        if old_status_id is not None:
            old_status = db.query(ProjectStatus).filter(
                ProjectStatus.id == old_status_id
            ).first()

    # Terapkan perubahan dan catat field yang benar-benar berubah.
    # Nilai lama dibaca saat itu juga, sehingga field yang ditambahkan otomatis
    # (pipeline_status di atas) ikut tertangani.
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

            # status_id memiliki log tersendiri di bawah
            if field != "status_id":
                label = labels.get(field, field)
                perubahan.append(
                    f"{label}: {old_value} → {value}"
                )

    # Catat riwayat status project
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

    # Catat perubahan field lainnya
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