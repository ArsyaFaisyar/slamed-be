
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func

from app.db.database import Base


class Branch(Base):
    __tablename__ = "branches"

    id = Column(Integer, primary_key=True, index=True)
    nama = Column(String(150), nullable=False, unique=True)
    kode = Column(String(30), nullable=False, unique=True)
    alamat = Column(String(255), nullable=True)
    no_telepon = Column(String(30), nullable=True)
    email = Column(String(150), nullable=True)
    website = Column(String(255), nullable=True)
    nama_direktur = Column(String(150), nullable=True)
    logo = Column(String(255), nullable=True)

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
