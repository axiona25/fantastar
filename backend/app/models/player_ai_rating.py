"""Voti dinamici da analisi cronaca live (keyword locale)."""
from datetime import datetime
from sqlalchemy import String, Integer, Float, Boolean, DateTime, ForeignKey, Index, func, JSON
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class PlayerAIRating(Base):
    __tablename__ = "player_ai_ratings"
    __table_args__ = (
        Index("idx_player_ai_ratings_match", "match_id"),
        Index("idx_player_ai_ratings_player_match", "player_id", "match_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    player_id: Mapped[int] = mapped_column(Integer, ForeignKey("players.id", ondelete="CASCADE"), nullable=False)
    match_id: Mapped[int] = mapped_column(Integer, ForeignKey("matches.id", ondelete="CASCADE"), nullable=False)
    minute: Mapped[int] = mapped_column(Integer, nullable=False)
    rating: Mapped[float] = mapped_column(Float, nullable=False)
    trend: Mapped[str] = mapped_column(String(10), default="stable")
    mentions: Mapped[int] = mapped_column(Integer, default=0)
    key_actions: Mapped[list | None] = mapped_column(JSON, nullable=True)
    source: Mapped[str] = mapped_column(String(20), default="local")
    is_final: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime | None] = mapped_column(DateTime, onupdate=func.now())
