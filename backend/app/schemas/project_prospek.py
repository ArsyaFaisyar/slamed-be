
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict


class ProjectProspekCreate(BaseModel):
    customer_id: int
    nama_project: str
    sales_id: int
    deskripsi: str | None = None
    status_id: int | None = None
    nilai_proyek: Decimal | None = None
    estimasi_closing: date | None = None


class ProjectProspekUpdate(BaseModel):
    customer_id: int | None = None
    nama_project: str | None = None
    deskripsi: str | None = None
    status_id: int | None = None
    nilai_proyek: Decimal | None = None
    estimasi_closing: date | None = None
    sales_id: int | None = None


class ProjectStatusResponse(BaseModel):
    id: int
    nama: str
    warna: str | None = None
    urutan: int
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class ProjectSalesResponse(BaseModel):
    id: int
    nama: str

    model_config = ConfigDict(from_attributes=True)


class ProjectProspekResponse(BaseModel):
    id: int
    customer_id: int
    nama_project: str
    deskripsi: str | None = None
    status_id: int | None = None
    status_rel: ProjectStatusResponse | None = None

    sales_id: int
    sales_rel: ProjectSalesResponse | None = None

    nilai_proyek: Decimal | None = None
    estimasi_closing: date | None = None
    created_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)


ProjectProspekResponse.model_rebuild()
