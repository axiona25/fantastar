import uuid
from datetime import datetime
from sqlalchemy import Boolean, Integer, DateTime, ForeignKey, func
from sqlalchemy import REAL
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class LeagueMatch(Base):
    __tablename__ = "league_matches"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    league_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("fantasy_leagues.id", ondelete="CASCADE"), nullable=False
    )
    round_number: Mapped[int] = mapped_column(Integer, nullable=False)
    serie_a_matchday: Mapped[int] = mapped_column(Integer, nullable=False)
    home_team_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("fantasy_teams.id", ondelete="CASCADE"), nullable=False
    )
    away_team_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("fantasy_teams.id", ondelete="CASCADE"), nullable=False
    )
    home_score: Mapped[float | None] = mapped_column(REAL, nullable=True)
    away_score: Mapped[float | None] = mapped_column(REAL, nullable=True)
    is_return_leg: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    played: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime | None] = mapped_column(DateTime, server_default=func.now(), nullable=True)
