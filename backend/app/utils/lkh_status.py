from datetime import datetime
from zoneinfo import ZoneInfo

from app.models.rkh import RKH

WIB = ZoneInfo("Asia/Jakarta")


def get_status_pengisian(
    rkh: RKH,
    waktu_test: datetime | None = None,
) -> str:
    sekarang = waktu_test or datetime.now(WIB)

    if sekarang.tzinfo is None:
        sekarang = sekarang.replace(tzinfo=WIB)
    else:
        sekarang = sekarang.astimezone(WIB)

    tanggal_rencana = rkh.tanggal_rencana

    if sekarang.date() > tanggal_rencana:
        return "LOCKED_LATE"

    if (
        sekarang.date() == tanggal_rencana
        and sekarang.hour >= 21
    ):
        return "LATE"

    return "ON_TIME"