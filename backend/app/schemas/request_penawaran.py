from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict, computed_field

class RequestPenawaranCreate(BaseModel):
    lkh_id: int
    diminta_oleh: Optional[str] = None
    media_pengadaan_id: Optional[int] = None
    branch_id: Optional[int] = None
    mode_pagu: str = "DETAIL"
    pajak_harga_modal: Optional[str] = None

class RequestPenawaranUpdate(BaseModel):
    diminta_oleh: Optional[str] = None
    media_pengadaan_id: Optional[int] = None
    branch_id: Optional[int] = None
    mode_pagu: Optional[str] = None
    pajak_harga_modal: Optional[str] = None
    durasi: Optional[int] = None
    total_pagu: Optional[Decimal] = None

class RequestPenawaranResponse(BaseModel):
    id: int
    lkh_id: int
    tanggal_request: date
    diminta_oleh: Optional[str] = None
    media_pengadaan_id: Optional[int] = None
    branch_id: Optional[int] = None
    mode_pagu: str
    pajak_harga_modal: Optional[str] = None
    status_request: str
    total_pagu: Optional[Decimal] = None
    total_harga_modal: Optional[Decimal] = None
    total_harga_jual: Optional[Decimal] = None
    created_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    @computed_field
    @property
    def sla_label(self) -> str:
        from app.utils.sla import hitung_sla
        return hitung_sla(self.created_at, self.completed_at)

    model_config = ConfigDict(from_attributes=True)

class RequestPenawaranItemCreate(BaseModel):
    nama_barang: str
    merk: Optional[str] = None
    tkdn: Optional[str] = None
    tkdn_persen: Optional[Decimal] = None
    spesifikasi: Optional[str] = None
    catatan_sales: Optional[str] = None
    jumlah: Decimal = Decimal("1")
    satuan: str = "Unit"

class RequestPenawaranItemUpdate(BaseModel):
    nama_barang: Optional[str] = None
    merk: Optional[str] = None
    tkdn: Optional[str] = None
    tkdn_persen: Optional[Decimal] = None
    spesifikasi: Optional[str] = None
    catatan_sales: Optional[str] = None
    jumlah: Optional[Decimal] = None
    satuan: Optional[str] = None
    harga_pagu: Optional[Decimal] = None
    harga_modal: Optional[Decimal] = None
    harga_jual: Optional[Decimal] = None

class RequestPenawaranItemResponse(BaseModel):
    id: int
    request_penawaran_id: int
    nama_barang: str
    merk: Optional[str] = None
    tkdn: Optional[str] = None
    tkdn_persen: Optional[Decimal] = None
    spesifikasi: Optional[str] = None
    catatan_sales: Optional[str] = None
    jumlah: Decimal
    satuan: str
    harga_pagu: Optional[Decimal] = None
    harga_modal: Optional[Decimal] = None
    harga_jual: Optional[Decimal] = None

    model_config = ConfigDict(from_attributes=True)