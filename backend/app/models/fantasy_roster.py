import uuid
from datetime import datetime
from decimal import Decimal
from sqlalchemy import Integer, Boolean, Numeric, DateTime, ForeignKey, UniqueConstraint, Index, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class FantasyRoster(Base):
    __tablename__ = "fantasy_rosters"
    __table_args__ = (
        UniqueConstraint("fantasy_team_id", "player_id", name="uq_fantasy_rosters_team_player"),
        Index("idx_roster_team", "fantasy_team_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    fantasy_team_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("fantasy_teams.id", ondelete="CASCADE"), nullable=False)
    league_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("fantasy_leagues.id", ondelete="CASCADE"), nullable=True)
    player_id: Mapped[int] = mapped_column(Integer, ForeignKey("players.id"), nullable=False)
    purchase_price: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    purchased_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
