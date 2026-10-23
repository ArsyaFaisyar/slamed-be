from pydantic import BaseModel, ConfigDict, Field, EmailStr


class BranchCreate(BaseModel):
    nama: str = Field(min_length=1, max_length=150)
    kode: str = Field(min_length=1, max_length=30)
    alamat: str | None = Field(default=None, max_length=255)
    no_telepon: str | None = Field(default=None, max_length=30)
    email: EmailStr | None = None
    website: str | None = Field(default=None, max_length=255)
    nama_direktur: str | None = Field(default=None, max_length=150)
class BranchUpdate(BaseModel):
    nama: str | None = Field(default=None, min_length=1, max_length=150)
    kode: str | None = Field(default=None, min_length=1, max_length=30)
    alamat: str | None = Field(default=None, max_length=255)
    no_telepon: str | None = Field(default=None, max_length=30)
    email: EmailStr | None = None
    website: str | None = Field(default=None, max_length=255)
    nama_direktur: str | None = Field(default=None, max_length=150)
class BranchResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nama: str
    kode: str
    alamat: str | None
    no_telepon: str | None
    email: str | None
    website: str | None
    nama_direktur: str | None
    logo: str | None
    cover_image: str | None
    signature_image: str | None