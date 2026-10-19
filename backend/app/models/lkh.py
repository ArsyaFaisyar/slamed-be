from sqlalchemy import (
    Column, Integer, String, Date, DateTime,
    Text, Numeric, ForeignKey
)
from sqlalchemy.sql import func
from app.db.database import Base

class LKH(Base):
    __tablename__ = "lkh"
    id = Column(Integer, primary_key=True, index=True)
    rkh_id = Column(
        Integer,
        ForeignKey("rkh.id"),
        nullable=False
    )
    sales_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )
    tanggal_kunjungan = Column(Date, nullable=False)

    hasil_kunjungan = Column(Text, nullable=False)
    status_prospek = Column(String(30), nullable=True)
    tindak_lanjut = Column(Text, nullable=True)

    latitude = Column(Numeric(10, 7), nullable=True)
    longitude = Column(Numeric(10, 7), nullable=True)
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )