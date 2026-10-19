from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Numeric
from sqlalchemy.sql import func
from app.db.database import Base


class Area(Base):
    __tablename__ = "areas"
    id = Column(Integer, primary_key=True, index=True)
    nama = Column(String(100), nullable=False, unique=True)
    spv_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
    )
    target = Column(
        Numeric(15, 2),
        nullable=False,
        default=0,
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