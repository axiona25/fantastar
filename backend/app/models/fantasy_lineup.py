import uuid
from datetime import datetime
from sqlalchemy import String, Integer, Boolean, DateTime, ForeignKey, UniqueConstraint, Index, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class FantasyLineup(Base):
    __tablename__ = "fantasy_lineups"
    __table_args__ = (
        UniqueConstraint("fantasy_team_id", "matchday", "player_id", name="uq_fantasy_lineups_team_matchday_player"),
        Index("idx_lineup_team_matchday", "fantasy_team_id", "matchday"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    fantasy_team_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("fantasy_teams.id", ondelete="CASCADE"), nullable=False)
    matchday: Mapped[int] = mapped_column(Integer, nullable=False)
    player_id: Mapped[int] = mapped_column(Integer, ForeignKey("players.id"), nullable=False)
    position_slot: Mapped[str] = mapped_column(String(10), nullable=False)
    is_starter: Mapped[bool] = mapped_column(Boolean, default=True)
    bench_order: Mapped[int | None] = mapped_column(Integer, nullable=True)
    formation: Mapped[str | None] = mapped_column(String(10), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
