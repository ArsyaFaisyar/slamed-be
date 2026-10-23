from datetime import datetime
from pydantic import BaseModel, ConfigDict

class ProjectLogCreate(BaseModel):
    aktivitas: str
    deskripsi: str | None = None
class ProjectLogResponse(BaseModel):
    id: int
    project_id: int
    user_id: int
    aktivitas: str
    deskripsi: str | None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)