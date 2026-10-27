from pydantic import BaseModel, Field
from decimal import Decimal

class RevisiItemUpdate(BaseModel):
    id: int
    nama_barang: str = Field(min_length=1)
    merk: str | None = None
    tkdn: str | None = None
    tkdn_persen: Decimal | None = None
    spesifikasi: str | None = None
    catatan_sales: str | None = None
    jumlah: Decimal = Field(gt=0)
    satuan: str = Field(min_length=1)
    harga_pagu: Decimal | None = None
    harga_modal: Decimal | None = None
    harga_jual: Decimal | None = None

class RevisiPenawaranUpdate(BaseModel):
    catatan_sales: str | None = None
    items: list[RevisiItemUpdate] = Field(min_length=1)
