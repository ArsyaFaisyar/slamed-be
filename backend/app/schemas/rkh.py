from pydantic import BaseModel, ConfigDict
from datetime import date, datetime
from decimal import Decimal
from typing import Optional


class RKHCreate(BaseModel):
    customer_id: int
    project_id: int
    tanggal_rencana: date
    tanggal_pelaksanaan: date
    judul_kegiatan: str
    rencana_kegiatan: str
    tipe_aktivitas: str
    estimasi_biaya_harian: Decimal = Decimal("0")


class RKHUpdate(BaseModel):
    customer_id: Optional[int] = None
    project_id: Optional[int] = None
    tanggal_rencana: Optional[date] = None
    tanggal_pelaksanaan: Optional[date] = None
    judul_kegiatan: Optional[str] = None
    rencana_kegiatan: Optional[str] = None
    tipe_aktivitas: Optional[str] = None
    estimasi_biaya_harian: Optional[Decimal] = None
    status: Optional[str] = None


class RKHResponse(BaseModel):
    id: int
    sales_id: int
    customer_id: int
    project_id: int
    tanggal_rencana: date
    tanggal_pelaksanaan: date
    judul_kegiatan: str
    rencana_kegiatan: str
    tipe_aktivitas: str
    estimasi_biaya_harian: Decimal
    status: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)