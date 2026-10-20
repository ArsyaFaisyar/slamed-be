from datetime import datetime
from pydantic import BaseModel, ConfigDict
from typing import Optional

class CustomerCategoryCreate(BaseModel):
    nama: str
class CustomerCategoryUpdate(BaseModel):
    nama: Optional[str] = None
class CustomerCategoryResponse(BaseModel):
    id: int
    nama: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    model_config = ConfigDict(from_attributes=True)