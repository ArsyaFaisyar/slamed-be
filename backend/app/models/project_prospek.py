from sqlalchemy import (
    Column, Integer, String, Text, DateTime, ForeignKey, Numeric, Date
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.database import Base


class ProjectProspek(Base):
    __tablename__ = "project_prospek"
    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(
        Integer,
        ForeignKey("customers.id"),
        nullable=False,
    )
    nama_project = Column(String(150), nullable=False)
    deskripsi = Column(Text, nullable=True)
    status_id = Column(
        Integer,
        ForeignKey("project_statuses.id"),
        nullable=True,
    )
    status_rel = relationship("ProjectStatus")
    sales_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )
    nilai_proyek = Column(
        Numeric(15, 2),
        nullable=True
    )

    estimasi_closing = Column(
        Date,
        nullable=True
    )
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )