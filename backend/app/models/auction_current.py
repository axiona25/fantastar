"""Stato corrente asta: un giocatore per lega, offerta massima e scadenza."""
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import Integer, Numeric, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class AuctionCurrent(Base):
    __tablename__ = "auction_current"

    league_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("fantasy_leagues.id", ondelete="CASCADE"), primary_key=True
    )
    player_id: Mapped[int] = mapped_column(Integer, ForeignKey("players.id"), nullable=False)
    highest_bid: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0)
    highest_bidder_team_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("fantasy_teams.id"), nullable=True
    )
    ends_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    round_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
