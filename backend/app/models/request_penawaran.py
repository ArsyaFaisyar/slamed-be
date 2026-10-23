from sqlalchemy import (
    Column,
    Integer,
    String,
    DateTime,
    Boolean,
    ForeignKey,
    Numeric,
    Date
)
from sqlalchemy.sql import func
from app.db.database import Base

class RequestPenawaran(Base):
    __tablename__ = "request_penawaran"
    id = Column(Integer, primary_key=True, index=True)
    lkh_id = Column(
        Integer,
        ForeignKey("lkh.id"),
        nullable=False,
        unique=True,
    )
    diminta_oleh = Column(String(150), nullable=True)
    media_pengadaan_id = Column(
        Integer,
        ForeignKey("media_pengadaan.id"),
        nullable=True
    )
    branch_id = Column(
        Integer,
        ForeignKey("branches.id"),
        nullable=True,
    )
    mode_pagu = Column(
        String(20),
        nullable=False,
        default="DETAIL",
        server_default="DETAIL",
    )
    pajak_harga_modal = Column(
        String(30),
        nullable=True,
    )
    status_request = Column(
        String(30),
        nullable=False,
        default="BARU",
        server_default="BARU",
    )
    nama_pic = Column(String(150), nullable=True)
    nomor_pic = Column(String(30), nullable=True)
    total_pagu = Column(Numeric(15, 2), nullable=True)
    total_harga_modal = Column(Numeric(15, 2), nullable=True)
    total_harga_jual = Column(Numeric(15, 2), nullable=True)
    
    tanggal_request = Column(Date, nullable=False, server_default=func.current_date())

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
    completed_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )
