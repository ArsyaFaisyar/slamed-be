from pydantic import BaseModel, ConfigDict
from datetime import date, datetime
from typing import Optional


class LKHCreate(BaseModel):
    rkh_id: int
    tanggal_kunjungan: date
    hasil_kunjungan: str
    status_prospek: Optional[str] = None
    tindak_lanjut: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class LKHUpdate(BaseModel):
    tanggal_kunjungan: Optional[date] = None
    hasil_kunjungan: Optional[str] = None
    status_prospek: Optional[str] = None
    tindak_lanjut: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class LKHResponse(BaseModel):
    id: int
    rkh_id: int
    sales_id: int
    tanggal_kunjungan: date
    hasil_kunjungan: str
    status_prospek: Optional[str] = None
    tindak_lanjut: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)