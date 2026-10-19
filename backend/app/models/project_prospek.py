from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.sql import func

from app.db.database import Base


class ProjectProspek(Base):
    __tablename__ = "project_prospek"

    id = Column(Integer, primary_key=True, index=True)

    customer_id = Column(
        Integer,
        ForeignKey("customers.id"),
        nullable=False
    )

    nama_project = Column(String(150), nullable=False)
    jenis = Column(String(30), nullable=False)  # PROJECT atau PROSPEK
    deskripsi = Column(Text, nullable=True)
    status = Column(String(30), nullable=False, default="BARU")

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )