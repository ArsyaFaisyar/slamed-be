from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session, joinedload

from app.db.database import get_db
from app.models.customer import Customer
from app.models.project_prospek import ProjectProspek
from app.models.project_status import ProjectStatus
from app.models.user import User
from app.schemas.project_prospek import (
    ProjectProspekCreate,
    ProjectProspekUpdate,
    ProjectProspekResponse,
)
from app.core.dependencies import get_current_user, require_roles

router = APIRouter(prefix="/projects", tags=["Projects"])

def get_project_query(db: Session, current_user: User):
    query = db.query(ProjectProspek).options(
        joinedload(ProjectProspek.status_rel)
    )

    if current_user.role == "SALES":
        query = query.join(
            Customer,
            ProjectProspek.customer_id == Customer.id,
        ).filter(ProjectProspek.sales_id == current_user.id)

    elif current_user.role not in ("SUPERADMIN", "SPV"):
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


@router.post("/", response_model=ProjectProspekResponse, status_code=201)
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
    sales = db.query(User).filter(
        User.id == data.sales_id,
        User.role == "SALES",
    ).first()

    if not sales:
        raise HTTPException(
            status_code=404,
            detail="Sales tidak ditemukan",
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
            detail="Belum ada status project aktif"
        )

    project = ProjectProspek(
        customer_id=data.customer_id,
        nama_project=data.nama_project,
        nilai_proyek=data.nilai_proyek,
        estimasi_closing=data.estimasi_closing,
        sales_id=data.sales_id,
        status_id=initial_status.id,
    )

    db.add(project)
    db.commit()
    db.refresh(project)

    return project


@router.patch("/{project_id}", response_model=ProjectProspekResponse)
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

    if "customer_id" in updates:
        customer = db.query(Customer).filter(
            Customer.id == updates["customer_id"]
        ).first()

        if not customer:
            raise HTTPException(
                status_code=404,
                detail="Customer tidak ditemukan",
            )

    for field, value in updates.items():
        setattr(project, field, value)

    db.commit()
    db.refresh(project)

    return project


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
