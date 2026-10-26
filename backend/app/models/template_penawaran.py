from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.sql import func

from app.db.database import Base

class TemplatePenawaran(Base):
    __tablename__ = "template_penawaran"
    id = Column(Integer, primary_key=True, index=True)
    judul = Column(String(150), nullable=False)
    konten = Column(Text, nullable=False)
    preview_path = Column(String(255), nullable=True)
    created_by = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
    )
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )
