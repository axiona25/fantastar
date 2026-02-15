from datetime import datetime
from sqlalchemy import String, Integer, DateTime, ForeignKey, Index, func
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class MatchEvent(Base):
    __tablename__ = "match_events"
    __table_args__ = (
        Index("idx_match_events_match", "match_id"),
        Index("idx_match_events_player", "player_id"),
        Index("idx_match_events_type", "event_type"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    match_id: Mapped[int] = mapped_column(Integer, ForeignKey("matches.id", ondelete="CASCADE"), nullable=False)
    player_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("players.id"), nullable=True)
    assist_player_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("players.id"), nullable=True)
    team_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("real_teams.id"), nullable=True)
    event_type: Mapped[str] = mapped_column(String(30), nullable=False)
    minute: Mapped[int] = mapped_column(Integer, nullable=False)
    extra_minute: Mapped[int | None] = mapped_column(Integer, nullable=True)
    detail: Mapped[str | None] = mapped_column(String(100), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
