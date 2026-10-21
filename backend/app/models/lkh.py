from sqlalchemy import (
    Column, Integer, Date, DateTime,
    Text, Numeric, ForeignKey, String
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
    tanggal_follow_up = Column(Date, nullable=True)
    hasil_kunjungan = Column(Text, nullable=False)
    status_lkh = Column(
        String(20),
        nullable=False,
        default="NOT_YET",
        server_default="NOT_YET",
    )
    tindak_lanjut = Column(Text, nullable=True)

    nama_pic = Column(String(150), nullable=False)
    nomor_pic = Column(String(30), nullable=False)

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