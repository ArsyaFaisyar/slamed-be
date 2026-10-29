
from sqlalchemy import (
    Column,
    Integer,
    String,
    Text,
    Numeric,
    ForeignKey,
)
from app.db.database import Base


class RevisiPenawaranItem(Base):
    __tablename__ = "revisi_penawaran_items"

    id = Column(Integer, primary_key=True, index=True)

    revisi_penawaran_id = Column(
        Integer,
        ForeignKey("revisi_penawaran.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    nama_barang = Column(String(150), nullable=False)
    merk = Column(String(150), nullable=True)
    tkdn = Column(String(30), nullable=True)
    tkdn_persen = Column(Numeric(5, 2), nullable=True)
    spesifikasi = Column(Text, nullable=True)
    catatan_sales = Column(Text, nullable=True)

    jumlah = Column(Numeric(12, 2), nullable=False)
    satuan = Column(String(50), nullable=False)

    # Informasi gambar, marketplace, dan pajak per barang
    gambar_path = Column(String, nullable=True)
    link_marketplace = Column(String, nullable=True)
    jenis_pajak = Column(
        String(20),
        nullable=False,
        default="PAJAK",
        server_default="PAJAK",
    )

    harga_pagu = Column(Numeric(15, 2), nullable=True)
    harga_modal = Column(Numeric(15, 2), nullable=True)
    harga_jual = Column(Numeric(15, 2), nullable=True)

    jenis_revisi = Column(
        String(30),
        nullable=False,
        default="REVISI_HARGA_BARANG",
        server_default="REVISI_HARGA_BARANG",
    )
