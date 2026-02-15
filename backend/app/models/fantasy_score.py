import uuid
from datetime import datetime
from decimal import Decimal
from sqlalchemy import String, Integer, Numeric, DateTime, ForeignKey, UniqueConstraint, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class FantasyScore(Base):
    __tablename__ = "fantasy_scores"
    __table_args__ = (
        UniqueConstraint("fantasy_team_id", "matchday", name="uq_fantasy_scores_team_matchday"),
        Index("idx_scores_matchday", "matchday"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    fantasy_team_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("fantasy_teams.id", ondelete="CASCADE"), nullable=False)
    matchday: Mapped[int] = mapped_column(Integer, nullable=False)
    total_score: Mapped[Decimal] = mapped_column(Numeric(6, 2), default=0)
    fantasy_goals: Mapped[int] = mapped_column(Integer, default=0)
    opponent_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("fantasy_teams.id"), nullable=True)
    opponent_score: Mapped[Decimal | None] = mapped_column(Numeric(6, 2), nullable=True)
    opponent_goals: Mapped[int | None] = mapped_column(Integer, nullable=True)
    result: Mapped[str | None] = mapped_column(String(1), nullable=True)  # W, D, L
    points_earned: Mapped[int | None] = mapped_column(Integer, nullable=True)
    detail_json: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    calculated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
