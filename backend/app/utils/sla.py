from datetime import datetime, date
from zoneinfo import ZoneInfo

WIB = ZoneInfo("Asia/Jakarta")

def hitung_sla(created_at: datetime, completed_at: datetime | None) -> str:
    sekarang = datetime.now(WIB)
    mulai = (
        created_at.replace(tzinfo=WIB)
        if created_at.tzinfo is None
        else created_at.astimezone(WIB)
    )
    if completed_at is not None:
        selesai = (
            completed_at.replace(tzinfo=WIB)
            if completed_at.tzinfo is None
            else completed_at.astimezone(WIB)
        )
        jumlah_hari = (selesai.date() - mulai.date()).days
        if jumlah_hari == 0:
            return "Selesai di hari yang sama"
        return f"Selesai dalam {jumlah_hari} hari"
    jumlah_hari = (sekarang.date() - mulai.date()).days
    if jumlah_hari == 0:
        return "Berjalan hari ini"      