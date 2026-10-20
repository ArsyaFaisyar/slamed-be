from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
)
from sqlalchemy.sql import func
from app.db.database import Base


class ProjectStatus(Base):
    __tablename__ = "project_statuses"
    id = Column(Integer, primary_key=True, index=True)
    nama = Column(String(100), unique=True, nullable=False)
    warna = Column(String(20), nullable=True)
    urutan = Column(Integer, nullable=False, default=0)
    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
        server_default="true",
    )
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )