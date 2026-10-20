from pydantic import BaseModel, ConfigDict, Field

class AreaCreate(BaseModel):
    nama: str = Field(min_length=1, max_length=100)
    spv_id: int = Field(gt=0)
    target: float = Field(ge=0)
class AreaUpdate(BaseModel):
    nama: str | None = Field(default=None, min_length=1, max_length=100)
    spv_id: int | None = Field(default=None, gt=0)
    target: float | None = Field(default=None, ge=0)
class AreaResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    nama: str
    spv_id: int
    target: float