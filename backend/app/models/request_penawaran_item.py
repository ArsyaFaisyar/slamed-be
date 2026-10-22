from sqlalchemy import (
    Column,
    Integer,
    String,
    Text,
    Numeric,
    ForeignKey,
    DateTime,
    Date
)
from sqlalchemy.sql import func
from app.db.database import Base

class RequestPenawaranItem(Base):
    __tablename__ = "request_penawaran_items"
    id = Column(Integer, primary_key=True, index=True)
    request_penawaran_id = Column(
        Integer,
        ForeignKey("request_penawaran.id", ondelete="CASCADE"),
        nullable=False,
    )
    nama_barang = Column(String(150), nullable=False)
    merk = Column(String(150), nullable=True)
    tkdn = Column(String(30), nullable=True)
    tkdn_persen = Column(Numeric(5, 2), nullable=True)
    spesifikasi = Column(Text, nullable=True)
    catatan_sales = Column(Text, nullable=True)
    jumlah = Column(Numeric(12, 2), nullable=False, default=1)
    satuan = Column(String(50), nullable=False, default="Unit")
    
    harga_pagu = Column(Numeric(15, 2), nullable=True)
    harga_modal = Column(Numeric(15, 2), nullable=True)
    harga_jual = Column(Numeric(15, 2), nullable=True)
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
