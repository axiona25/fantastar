"""Sedia al tavolo asta live: league_id, seat_number, team_id, heartbeat."""
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Integer, ForeignKey, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class AuctionSeat(Base):
    __tablename__ = "auction_seats"
    __table_args__ = (
        UniqueConstraint("league_id", "seat_number", name="uq_auction_seats_league_seat"),
        UniqueConstraint("league_id", "team_id", name="uq_auction_seats_league_team"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    league_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("fantasy_leagues.id", ondelete="CASCADE"), nullable=False
    )
    seat_number: Mapped[int] = mapped_column(Integer, nullable=False)
    team_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("fantasy_teams.id", ondelete="CASCADE"), nullable=False
    )
    joined_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    last_heartbeat: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
