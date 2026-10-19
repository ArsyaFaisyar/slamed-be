from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime

class CustomerCreate(BaseModel):
    nama_instansi: str
    nama_pic: Optional[str] = None
    kontak_pic: Optional[str] = None
    kota: Optional[str] = None
    kategori: Optional[str] = None
    area: Optional[str] = None
    sales_id: Optional[int] = None
class CustomerUpdate(BaseModel):
    nama_instansi: Optional[str] = None
    nama_pic: Optional[str] = None
    kontak_pic: Optional[str] = None
    kota: Optional[str] = None
    kategori: Optional[str] = None
    area: Optional[str] = None
    sales_id: Optional[int] = None
class CustomerResponse(BaseModel):
    id: int
    nama_instansi: str
    nama_pic: Optional[str] = None
    kontak_pic: Optional[str] = None
    kota: Optional[str] = None
    kategori: Optional[str] = None
    area: Optional[str] = None
    sales_id: Optional[int] = None
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)