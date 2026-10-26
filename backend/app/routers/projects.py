
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
                (ProjectProspek.pipeline_status == "Prospek", 1),
                else_=0,
            )
        ).label("jumlah_prospek"),

        func.sum(
            case(
                (ProjectProspek.pipeline_status == "Hot Prospek", 1),
                else_=0,
            )
        ).label("jumlah_hot_prospek"),

        func.coalesce(
            func.sum(
                case(
                    (
                        ProjectProspek.pipeline_status == "Prospek",
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
                        ProjectProspek.pipeline_status == "Hot Prospek",
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
    if "pipeline_status" in updates:
        if updates["pipeline_status"] not in ("Prospek", "Hot Prospek"):
            raise HTTPException(
                status_code=400,
                detail="Pipeline status harus Prospek atau Hot Prospek",
            )
    old_status_id = project.status_id
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

    for field, value in updates.items():
        setattr(project, field, value)

    if (
        "status_id" in updates
        and project.status_id != old_status_id
    ):
        old_status = (
            db.query(ProjectStatus)
            .filter(ProjectStatus.id == old_status_id)
            .first()
        )

        new_status = (
            db.query(ProjectStatus)
            .filter(ProjectStatus.id == project.status_id)
            .first()
        )

        if not new_status:
            raise HTTPException(
                status_code=400,
                detail="Status project tidak ditemukan",
            )
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
    
    

    db.commit()

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
