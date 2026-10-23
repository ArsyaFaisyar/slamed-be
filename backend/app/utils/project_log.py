from sqlalchemy.orm import Session

from app.models.project_log import ProjectLog


def catat_project_log(
    db: Session,
    project_id: int,
    user_id: int,
    aktivitas: str,
    deskripsi: str | None = None,
):
    log = ProjectLog(
        project_id=project_id,
        user_id=user_id,
        aktivitas=aktivitas,
        deskripsi=deskripsi,
    )
    db.add(log)
    return log