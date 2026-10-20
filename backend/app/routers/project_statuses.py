from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.core.dependencies import get_current_user, require_roles
from app.models.project_status import ProjectStatus
from app.schemas.project_status import (
    ProjectStatusCreate,
    ProjectStatusUpdate,
    ProjectStatusResponse,
)

router = APIRouter(
    prefix="/project-statuses",
    tags=["Project Statuses"],
)

def check_duplicate_name(
    db: Session,
    nama: str,
    exclude_id: int | None = None,
):
    query = db.query(ProjectStatus).filter(
        func.lower(ProjectStatus.nama) == nama.strip().lower()
    )
    if exclude_id is not None:
        query = query.filter(ProjectStatus.id != exclude_id)
    if query.first():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Nama status sudah digunakan.",
        )

@router.get(
    "",
    response_model=list[ProjectStatusResponse],
)
def get_project_statuses(
    include_inactive: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(
        require_roles("SUPERADMIN", "SPV", "SALES")
    ),
):
    query = db.query(ProjectStatus)
    if current_user.role == "SALES":
        query = query.filter(ProjectStatus.is_active.is_(True))
    elif not include_inactive:
        query = query.filter(ProjectStatus.is_active.is_(True))

    return query.order_by(
        ProjectStatus.urutan.asc(),
        ProjectStatus.id.asc(),
    ).all()

@router.get(
    "/{status_id}",
    response_model=ProjectStatusResponse,
)
def get_project_status(
    status_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(
        require_roles("SUPERADMIN", "SPV")
    ),
):
    item = db.query(ProjectStatus).filter(
        ProjectStatus.id == status_id
    ).first()
    if not item:
        raise HTTPException(
            status_code=404,
            detail="Status proyek tidak ditemukan.",
        )
    return item

@router.post(
    "",
    response_model=ProjectStatusResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_project_status(
    payload: ProjectStatusCreate,
    db: Session = Depends(get_db),
    current_user=Depends(
        require_roles("SUPERADMIN", "SPV")
    ),
):
    nama = payload.nama.strip()
    if not nama:
        raise HTTPException(
            status_code=422,
            detail="Nama status tidak boleh kosong.",
        )
    check_duplicate_name(db, nama)
    item = ProjectStatus(
        nama=nama,
        warna=payload.warna,
        urutan=payload.urutan,
        is_active=True,
    )
    db.add(item)
    try:
        db.commit()
        db.refresh(item)
    except Exception:
        db.rollback()
        raise
    return item

@router.patch(
    "/{status_id}",
    response_model=ProjectStatusResponse,
)
def update_project_status(
    status_id: int,
    payload: ProjectStatusUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(
        require_roles("SUPERADMIN", "SPV")
    ),
):
    item = db.query(ProjectStatus).filter(
        ProjectStatus.id == status_id
    ).first()
    if not item:
        raise HTTPException(
            status_code=404,
            detail="Status proyek tidak ditemukan.",
        )
    changes = payload.model_dump(exclude_unset=True)
    if "nama" in changes:
        nama = changes["nama"]
        if nama is None or not nama.strip():
            raise HTTPException(
                status_code=422,
                detail="Nama status tidak boleh kosong.",
            )
        nama = nama.strip()
        check_duplicate_name(db, nama, exclude_id=status_id)
        changes["nama"] = nama

    for field, value in changes.items():
        setattr(item, field, value)
    try:
        db.commit()
        db.refresh(item)
    except Exception:
        db.rollback()
        raise
    return item


@router.delete(
    "/{status_id}",
    status_code=status.HTTP_200_OK,
)
def deactivate_project_status(
    status_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(
        require_roles("SUPERADMIN", "SPV")
    ),
):
    item = db.query(ProjectStatus).filter(
        ProjectStatus.id == status_id
    ).first()
    if not item:
        raise HTTPException(
            status_code=404,
            detail="Status proyek tidak ditemukan.",
        )
    item.is_active = False
    try:
        db.commit()
    except Exception:
        db.rollback()
        raise
    return {
        "message": "Status proyek berhasil dinonaktifkan.",
        "id": item.id,
        "is_active": item.is_active,
    }