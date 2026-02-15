"""Squalifiche automatiche (cartellini) o disciplinari."""
from datetime import datetime

from sqlalchemy import String, Integer, Boolean, DateTime, ForeignKey, Index, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class PlayerSuspension(Base):
    __tablename__ = "player_suspensions"
    __table_args__ = (Index("idx_suspensions_player_matchday", "player_id", "matchday_from"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    player_id: Mapped[int] = mapped_column(Integer, ForeignKey("players.id", ondelete="CASCADE"), nullable=False)
    reason: Mapped[str] = mapped_column(String(50), nullable=False)
    matchday_from: Mapped[int] = mapped_column(Integer, nullable=False)
    matchday_to: Mapped[int] = mapped_column(Integer, nullable=False)
    matches_count: Mapped[int] = mapped_column(Integer, default=1)
    season: Mapped[str] = mapped_column(String(10), default="2025")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
