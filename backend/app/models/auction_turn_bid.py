"""Offerta segreta (busta chiusa) per un giocatore in un turno asta random."""
import uuid
from datetime import datetime

from sqlalchemy import Integer, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class AuctionTurnBid(Base):
    __tablename__ = "auction_turn_bids"
    __table_args__ = (
        UniqueConstraint(
            "auction_turn_player_id",
            "fantasy_team_id",
            name="uq_auction_turn_bids_turn_player_team",
        ),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    auction_turn_player_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("auction_turn_players.id", ondelete="CASCADE"), nullable=False
    )
    fantasy_team_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("fantasy_teams.id", ondelete="CASCADE"), nullable=False
    )
    bid_amount: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
