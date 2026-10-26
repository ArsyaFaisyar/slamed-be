from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

class TemplatePenawaranCreate(BaseModel):
    judul: str = Field(min_length=1, max_length=150)
    konten: str = Field(min_length=1)
class TemplatePenawaranUpdate(BaseModel):
    judul: str | None = Field(
        default=None,
        min_length=1,
        max_length=150,
    )
    konten: str | None = Field(
        default=None,
        min_length=1,
    )
class TemplatePenawaranResponse(BaseModel):
    id: int
    judul: str
    konten: str
    preview_path: str | None = None
    created_by: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
