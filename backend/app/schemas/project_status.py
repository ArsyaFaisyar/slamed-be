from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

class ProjectStatusCreate(BaseModel):
    nama: str = Field(min_length=1, max_length=100)
    warna: str | None = Field(default=None, max_length=20)
    urutan: int = Field(default=0, ge=0)
class ProjectStatusUpdate(BaseModel):
    nama: str | None = Field(
        default=None,
        min_length=1,
        max_length=100,
    )
    warna: str | None = Field(default=None, max_length=20)
    urutan: int | None = Field(default=None, ge=0)
    is_active: bool | None = None
class ProjectStatusResponse(BaseModel):
    id: int
    nama: str
    warna: str | None
    urutan: int
    is_active: bool
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)