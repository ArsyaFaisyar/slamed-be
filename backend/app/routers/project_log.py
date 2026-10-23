
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.project_prospek import ProjectProspek
from app.models.project_log import ProjectLog
from app.models.project_status import ProjectStatus
from app.models.project_status_history import ProjectStatusHistory

router = APIRouter(prefix="/projects", tags=["Project Logs"])


@router.get("/{project_id}/logs")
def get_project_logs(
    project_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    project = (
        db.query(ProjectProspek)
        .filter(ProjectProspek.id == project_id)
        .first()
    )

    if not project:
        raise HTTPException(
            status_code=404,
            detail="Project tidak ditemukan",
        )

    if current_user.role == "SALES":
        if project.sales_id != current_user.id:
            raise HTTPException(
                status_code=403,
                detail="Kamu tidak memiliki akses ke log proyek ini",
            )
    elif current_user.role not in ("SUPERADMIN", "SPV"):
        raise HTTPException(
            status_code=403,
            detail="Kamu tidak memiliki akses ke log proyek",
        )

    logs = []
    project_logs = (
        db.query(ProjectLog)
        .filter(ProjectLog.project_id == project_id)
        .all()
    )

    for log in project_logs:
        logs.append({
            "id": f"log-{log.id}",
            "source": "activity",
            "aktivitas": log.aktivitas,
            "deskripsi": log.deskripsi,
            "user_id": log.user_id,
            "created_at": log.created_at,
        })

    status_histories = (
        db.query(ProjectStatusHistory)
        .filter(ProjectStatusHistory.project_id == project_id)
        .all()
    )

    for history in status_histories:
        old_status = (
            db.query(ProjectStatus)
            .filter(ProjectStatus.id == history.old_status_id)
            .first()
            if history.old_status_id is not None
            else None
        )

        new_status = (
            db.query(ProjectStatus)
            .filter(ProjectStatus.id == history.new_status_id)
            .first()
        )

        logs.append({
            "id": f"status-{history.id}",
            "source": "status_history",
            "aktivitas": "Status project berubah",
            "deskripsi": (
                f"Status berubah dari "
                f"{old_status.nama if old_status else 'Belum ada status'} "
                f"menjadi "
                f"{new_status.nama if new_status else 'Status tidak ditemukan'}."
            ),
            "user_id": history.changed_by,
            "created_at": history.created_at,
        })

    logs.sort(
        key=lambda item: item["created_at"],
        reverse=True,
    )

    return logs
