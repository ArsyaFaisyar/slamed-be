from sqlalchemy import (
    Column, Integer, Text, DateTime, ForeignKey
)
from sqlalchemy.sql import func
from app.db.database import Base

class ProjectStatusHistory(Base):
    __tablename__ = "project_status_histories"
    id = Column(Integer, primary_key=True, index=True)
    project_id = Column(
        Integer,
        ForeignKey("project_prospek.id"),
        nullable=False,
        index=True,
    )
    old_status_id = Column(
        Integer,
        ForeignKey("project_statuses.id"),
        nullable=True,
    )
    new_status_id = Column(
        Integer,
        ForeignKey("project_statuses.id"),
        nullable=False,
    )
    changed_by = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
    )
    source_lkh_id = Column(
        Integer,
        ForeignKey("lkh.id"),
        nullable=True,
    )
    catatan = Column(Text, nullable=True)
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )