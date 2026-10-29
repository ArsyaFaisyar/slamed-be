from pydantic import BaseModel, ConfigDict
from datetime import date, datetime
from typing import Optional, Literal


class LKHCreate(BaseModel):
    rkh_id: int
    tanggal_kunjungan: date
    hasil_kunjungan: str
    nama_pic: str
    nomor_pic: str
    status_lkh: Literal["NOT_YET", "DONE"] = "NOT_YET"
    tindak_lanjut: Optional[str] = None
    tanggal_follow_up: Optional[date] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    status_progres: Literal[
    "PROSPEK",
    "REQUEST_PENAWARAN",
    "REVISI_PENAWARAN",
    "ADMINISTRASI_SPK",
    "LOST",
] = "PROSPEK"


class LKHUpdate(BaseModel):
    tanggal_kunjungan: Optional[date] = None
    hasil_kunjungan: Optional[str] = None
    status_lkh: Optional[Literal["NOT_YET", "DONE"]] = None
    tindak_lanjut: Optional[str] = None
    tanggal_follow_up: Optional[date] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    nama_pic: Optional[str] = None
    nomor_pic: Optional[str] = None
    status_progres: Optional[
    Literal[
        "PROSPEK",
        "REQUEST_PENAWARAN",
        "REVISI_PENAWARAN",
        "ADMINISTRASI_SPK",
        "LOST",
    ]
] = None

class LKHResponse(BaseModel):
    id: int
    rkh_id: int
    sales_id: int
    tanggal_kunjungan: date
    hasil_kunjungan: str
    nama_pic: str
    nomor_pic: str
    status_lkh: Literal["NOT_YET", "DONE"]
    tindak_lanjut: Optional[str] = None
    tanggal_follow_up: Optional[date] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    model_config = ConfigDict(from_attributes=True)
    status_pengisian: str
    status_progres: str
    
class LKHExportSchema(BaseModel):
    id: int
    rkh_id: int
    sales_id: int
    tanggal_kunjungan: date
    tanggal_follow_up: Optional[date] = None
    hasil_kunjungan: str
    status_lkh: Literal["NOT_YET", "DONE"]
    tindak_lanjut: Optional[str] = None
    nama_pic: str
    nomor_pic: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)