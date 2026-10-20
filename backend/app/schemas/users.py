from pydantic import BaseModel, ConfigDict, EmailStr, Field
from typing import Literal, Optional


UserRole = Literal[
    "SUPERADMIN",
    "SPV",
    "SALES",
    "PPIC",
    "ADMIN_MARKETING",
    "ADMIN_KEUANGAN",
]


class UserCreate(BaseModel):
    nama: str = Field(min_length=1, max_length=100)
    username: str = Field(min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(min_length=8)
    role: UserRole
    branch_id: Optional[int] = None
    area_id: Optional[int] = None


class UserUpdate(BaseModel):
    nama: str | None = Field(default=None, min_length=1, max_length=100)
    email: EmailStr | None = None
    role: UserRole | None = None
    is_active: bool | None = None
    branch_id: Optional[int] = None
    area_id: Optional[int] = None

class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    nama: str
    username: str
    email: EmailStr
    role: str
    is_active: int
    branch_id: Optional[int] = None
    area_id: Optional[int] = None

class UserPasswordReset(BaseModel):
    password: str = Field(min_length=8)
class ChangePasswordRequest(BaseModel):
    password_lama: str
    password_baru: str = Field(min_length=6)