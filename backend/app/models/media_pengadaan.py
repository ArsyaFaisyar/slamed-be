from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func
from app.db.database import Base


class MediaPengadaan(Base):
    __tablename__ = "media_pengadaan"
    id = Column(Integer, primary_key=True, index=True)
    nama = Column(
        String(150),
        nullable=False,
        unique=True,
    )
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )