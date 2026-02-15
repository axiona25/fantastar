from datetime import datetime
from sqlalchemy import Integer, DateTime, ForeignKey, Index, func, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base


class Match(Base):
    __tablename__ = "matches"
    __table_args__ = (
        Index("idx_matches_matchday", "matchday"),
        Index("idx_matches_status", "status"),
        Index("idx_matches_kick_off", "kick_off"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    external_id: Mapped[int | None] = mapped_column(Integer, unique=True, nullable=True)
    espn_event_id: Mapped[str | None] = mapped_column(String(20), nullable=True)  # ESPN event id per dettaglio
    matchday: Mapped[int] = mapped_column(Integer, nullable=False)
    home_team_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("real_teams.id"), nullable=True)
    away_team_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("real_teams.id"), nullable=True)
    home_score: Mapped[int | None] = mapped_column(Integer, nullable=True)
    away_score: Mapped[int | None] = mapped_column(Integer, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="SCHEDULED")
    kick_off: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    minute: Mapped[int | None] = mapped_column(Integer, nullable=True)
    season: Mapped[str] = mapped_column(String(10), default="2025")
    last_synced: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
