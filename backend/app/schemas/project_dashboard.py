from decimal import Decimal
from pydantic import BaseModel

class ProjectDashboardSummary(BaseModel):
    jumlah_project: int
    total_nilai_project: Decimal
    jumlah_prospek: int
    jumlah_hot_prospek: int
    nilai_prospek: Decimal
    nilai_hot_prospek: Decimal