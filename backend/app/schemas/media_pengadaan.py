from pydantic import BaseModel, ConfigDict, Field

class MediaPengadaanCreate(BaseModel):
    nama: str = Field(min_length=1, max_length=150)
class MediaPengadaanUpdate(BaseModel):
    nama: str | None = Field(default=None, min_length=1, max_length=150)
class MediaPengadaanResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    nama: str