from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class ProjectProspekCreate(BaseModel):
    customer_id: int
    nama_project: str
    jenis: str = "PROSPEK"
    deskripsi: Optional[str] = None
    status_id: Optional[int] = None

class ProjectProspekUpdate(BaseModel):
    customer_id: Optional[int] = None
    nama_project: Optional[str] = None
    jenis: Optional[str] = None
    deskripsi: Optional[str] = None
    status_id: Optional[int] = None

class ProjectProspekResponse(BaseModel):
    id: int
    customer_id: int
    nama_project: str
    jenis: str
    deskripsi: Optional[str] = None
    status_id: Optional[int] = None
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)