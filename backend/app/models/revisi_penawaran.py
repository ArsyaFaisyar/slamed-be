from sqlalchemy import (
    Column,
    Integer,
    String,
    Text,
    Numeric,
    DateTime,
    ForeignKey,
)
from sqlalchemy.sql import func
from app.db.database import Base

class RevisiPenawaran(Base):
    __tablename__ = "revisi_penawaran"
    id = Column(Integer, primary_key=True, index=True)
    request_penawaran_id = Column(
        Integer,
        ForeignKey("request_penawaran.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    nomor_revisi = Column(Integer, nullable=False)
    jenis_revisi = Column(
        String(30),
        nullable=False,
        default="REVISI_HARGA_BARANG",
        server_default="REVISI_HARGA_BARANG",
    )

    alasan_revisi = Column(Text, nullable=False)
    catatan_sales = Column(Text, nullable=True)
    status_revisi = Column(
        String(30),
        nullable=False,
        default="DIMINTA",
        server_default="DIMINTA",
    )
    diminta_oleh = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
    )
    dikirim_oleh = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=True,
    )
    disetujui_oleh = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=True,
    )

    tanggal_diminta = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    tanggal_dikirim = Column(DateTime(timezone=True), nullable=True)
    tanggal_disetujui = Column(DateTime(timezone=True), nullable=True)

    total_penawaran = Column(Numeric(15, 2), nullable=True)
    cashback = Column(Numeric(15, 2), nullable=True)
    biaya_operasional = Column(Numeric(15, 2), nullable=True)

    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
