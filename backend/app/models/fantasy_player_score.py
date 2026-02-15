import uuid
from datetime import datetime
from decimal import Decimal
from sqlalchemy import Integer, Boolean, Numeric, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class FantasyPlayerScore(Base):
    __tablename__ = "fantasy_player_scores"
    __table_args__ = (UniqueConstraint("fantasy_team_id", "player_id", "matchday", name="uq_fantasy_player_scores_team_player_matchday"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    fantasy_team_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("fantasy_teams.id", ondelete="CASCADE"), nullable=False)
    player_id: Mapped[int] = mapped_column(Integer, ForeignKey("players.id"), nullable=False)
    match_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("matches.id"), nullable=True)
    matchday: Mapped[int] = mapped_column(Integer, nullable=False)
    base_score: Mapped[Decimal] = mapped_column(Numeric(5, 2), default=0)
    advanced_score: Mapped[Decimal] = mapped_column(Numeric(5, 2), default=0)
    total_score: Mapped[Decimal] = mapped_column(Numeric(5, 2), default=0)
    is_starter: Mapped[bool] = mapped_column(Boolean, default=True)
    was_subbed_in: Mapped[bool] = mapped_column(Boolean, default=False)
    events_json: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    calculated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
