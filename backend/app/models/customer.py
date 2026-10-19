from sqlalchemy import (
    Column, Integer, String, DateTime, ForeignKey
)
from sqlalchemy.sql import func

from app.db.database import Base


class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    nama_instansi = Column(String(150), nullable=False)
    nama_pic = Column(String(100), nullable=True)
    kontak_pic = Column(String(30), nullable=True)
    kota = Column(String(100), nullable=True)
    kategori = Column(String(50), nullable=True)
    area = Column(String(100), nullable=True)
    sales_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=True
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )