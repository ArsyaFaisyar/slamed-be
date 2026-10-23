
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class CustomerCreate(BaseModel):
    nama_instansi: str
    nama_pic: Optional[str] = None
    kontak_pic: Optional[str] = None
    kota: Optional[str] = None
    kategori: Optional[str] = None
    area_id: Optional[int] = None
    sales_id: Optional[int] = None


class CustomerUpdate(BaseModel):
    nama_instansi: Optional[str] = None
    nama_pic: Optional[str] = None
    kontak_pic: Optional[str] = None
    kota: Optional[str] = None
    kategori: Optional[str] = None
    area_id: Optional[int] = None
    sales_id: Optional[int] = None


class CustomerResponse(BaseModel):
    id: int
    nama_instansi: str

    nama_pic: Optional[str] = None
    kontak_pic: Optional[str] = None
    kota: Optional[str] = None
    kategori: Optional[str] = None

    area_id: Optional[int] = None
    area_nama: Optional[str] = None

    sales_id: Optional[int] = None
    sales_nama: Optional[str] = None

    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
