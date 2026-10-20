from sqlalchemy import (
    Column, Integer, String, Date, DateTime,
    Text, Numeric, ForeignKey
)
from sqlalchemy.sql import func
from app.db.database import Base

class RKH(Base):
    __tablename__ = "rkh"
    id = Column(Integer, primary_key=True, index=True)
    sales_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )
    customer_id = Column(
        Integer,
        ForeignKey("customers.id"),
        nullable=False
    )
    project_id = Column(
        Integer,
        ForeignKey("project_prospek.id"),
        nullable=False
    )

    tanggal_rencana = Column(Date, nullable=False)
    tanggal_pelaksanaan = Column(Date, nullable=False)

    judul_kegiatan = Column(String(150), nullable=False)
    rencana_kegiatan = Column(Text, nullable=False)
    tipe_aktivitas = Column(String(50), nullable=False)
    estimasi_biaya_harian = Column(
        Numeric(12, 2),
        nullable=False,
        default=0
    )
    status = Column(String(30), nullable=False, default="DRAFT")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )