from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime,date
from decimal import Decimal


class ProjectProspekCreate(BaseModel):
    customer_id: int
    nama_project: str
    deskripsi: Optional[str] = None
    status_id: Optional[int] = None
    nilai_proyek: Decimal | None = None
    estimasi_closing: date | None = None
    sales_id: int

class ProjectProspekUpdate(BaseModel):
    customer_id: Optional[int] = None
    nama_project: Optional[str] = None
    deskripsi: Optional[str] = None
    status_id: Optional[int] = None
    nilai_proyek: Decimal | None = None
    estimasi_closing: date | None = None
    sales_id: int | None = None

class ProjectProspekResponse(BaseModel):
    id: int
    customer_id: int
    nama_project: str
    deskripsi: Optional[str] = None
    status_id: Optional[int] = None
    nilai_proyek: Decimal | None = None
    estimasi_closing: date | None = None
    sales_id: int
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)