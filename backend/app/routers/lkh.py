from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.rkh import RKH
from app.models.lkh import LKH
from app.models.user import User
from app.models.project_prospek import ProjectProspek
from app.models.project_status import ProjectStatus
from app.models.project_status_history import ProjectStatusHistory
from app.schemas.lkh import LKHCreate, LKHUpdate, LKHResponse
from app.core.dependencies import get_current_user, require_roles

router = APIRouter(prefix="/lkh", tags=["LKH"])

def get_lkh_query(db: Session, current_user: User):
    query = db.query(LKH)

    if current_user.role == "SALES":
        query = query.filter(LKH.sales_id == current_user.id)
    elif current_user.role not in ("SUPERADMIN", "SPV"):
        raise HTTPException(
            status_code=403,
            detail="Kamu tidak memiliki akses ke laporan kunjungan",
        )
    return query

def apply_project_status(
    db: Session,
    project: ProjectProspek,
    status_id: int,
    user_id: int,
    lkh_id: int | None = None,
):

    status = db.query(ProjectStatus).filter(
        ProjectStatus.id == status_id
    ).first()

    if not status:
        raise HTTPException(404, "Status project tidak ditemukan")

    if not status.is_active:
        raise HTTPException(400, "Status project sudah tidak aktif")

    old_status_id = project.status_id

    if old_status_id == status_id:
        return

    already_visited = db.query(ProjectStatusHistory).filter(
        ProjectStatusHistory.project_id == project.id,
        ProjectStatusHistory.new_status_id == status_id,
    ).first()

    if already_visited:
        raise HTTPException(
            400,
            detail="Project ini pernah menggunakan status tersebut. "
                   "Status tidak dapat dipilih kembali.",
        )

    project.status_id = status_id

    history = ProjectStatusHistory(
        project_id=project.id,
        old_status_id=old_status_id,
        new_status_id=status_id,
        changed_by=user_id,
        source_lkh_id=lkh_id,
    )
    db.add(history)


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
    data: LKHCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV", "SALES")
    ),
):
    rkh = db.query(RKH).filter(RKH.id == data.rkh_id).first()
    if not rkh:
        raise HTTPException(404, "RKH tidak ditemukan")

    if current_user.role == "SALES" and rkh.sales_id != current_user.id:
        raise HTTPException(403, "RKH ini bukan tanggung jawabmu")
    existing_laporan = db.query(LKH).filter(
        LKH.rkh_id == rkh.id
    ).first()

    if existing_laporan:
        raise HTTPException(
            409,
            "RKH ini sudah memiliki laporan kunjungan",
        )

    project = db.query(ProjectProspek).filter(
        ProjectProspek.id == rkh.project_id
    ).with_for_update().first()

    if not project:
        raise HTTPException(404, "Project pada RKH tidak ditemukan")
    try:
        laporan = LKH(
            **data.model_dump(),
            sales_id=rkh.sales_id,
        )
        db.add(laporan)
        db.flush()

        apply_project_status(
            db=db,
            project=project,
            status_id=data.status_id,
            user_id=current_user.id,
            lkh_id=laporan.id,
        )

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

    updates = data.model_dump(exclude_unset=True)
    new_status_id = updates.pop("status_id", None)
    try:
        if new_status_id is not None:
            rkh = db.query(RKH).filter(
                RKH.id == laporan.rkh_id
            ).first()

            project = db.query(ProjectProspek).filter(
                ProjectProspek.id == rkh.project_id
            ).with_for_update().first()

            if not project:
                raise HTTPException(404, "Project tidak ditemukan")

            apply_project_status(
                db=db,
                project=project,
                status_id=new_status_id,
                user_id=current_user.id,
                lkh_id=laporan.id,
            )
            laporan.status_id = new_status_id

        for field, value in updates.items():
            setattr(laporan, field, value)

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

    has_history = db.query(ProjectStatusHistory).filter(
        ProjectStatusHistory.source_lkh_id == laporan.id
    ).first()

    if has_history:
        raise HTTPException(
            409,
            "LKH sudah tercatat dalam riwayat status project dan tidak "
            "dapat dihapus.",
        )

    db.delete(laporan)
    db.commit()
    return Response(status_code=204)
