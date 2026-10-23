from datetime import datetime
from zoneinfo import ZoneInfo

WIB = ZoneInfo("Asia/Jakarta")


def _ke_wib(nilai: datetime) -> datetime:
    if nilai.tzinfo is None:
        return nilai.replace(tzinfo=WIB)
    return nilai.astimezone(WIB)


def hitung_sla(created_at: datetime | None, completed_at: datetime | None) -> str:
    if created_at is None:
        return "-"

    mulai = _ke_wib(created_at)

    if completed_at is not None:
        selesai = _ke_wib(completed_at)
        jumlah_hari = (selesai.date() - mulai.date()).days

        if jumlah_hari <= 0:
            return "Selesai di hari yang sama"

        return f"Selesai dalam {jumlah_hari} hari"

    jumlah_hari = (datetime.now(WIB).date() - mulai.date()).days

    if jumlah_hari <= 0:
        return "Berjalan hari ini"

    return f"Berjalan {jumlah_hari} hari"