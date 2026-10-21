from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.db.database import Base


class LKHAttachment(Base):
    __tablename__ = "lkh_attachments"
    id = Column(Integer, primary_key=True, index=True)
    lkh_id = Column(
        Integer,
        ForeignKey("lkh.id", ondelete="CASCADE"),
        nullable=False
    )
    nama_file = Column(String(255), nullable=False)
    file_url = Column(String(500), nullable=False)
    tipe_file = Column(String(50), nullable=False)
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )
    jenis = Column(
        String(20),
        nullable=False,
        default="LAMPIRAN",
        server_default="LAMPIRAN",
    )