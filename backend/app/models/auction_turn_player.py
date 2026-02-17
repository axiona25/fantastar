"""Giocatore proposto in un turno asta random: vincitore e importo."""
import uuid
from datetime import datetime

from sqlalchemy import Integer, String, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class AuctionTurnPlayer(Base):
    __tablename__ = "auction_turn_players"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    auction_turn_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("auction_turns.id", ondelete="CASCADE"), nullable=False
    )
    player_id: Mapped[int] = mapped_column(Integer, ForeignKey("players.id"), nullable=False)
    winner_team_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("fantasy_teams.id", ondelete="SET NULL"), nullable=True
    )
    winning_bid: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="available", nullable=False)
