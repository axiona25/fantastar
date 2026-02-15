"""Sessione d'asta per una lega: status, giocatore corrente, timer, turni per categoria."""
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import Integer, Numeric, String, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


# Ordine categorie asta: POR → DIF → CEN → ATT
AUCTION_CATEGORY_ORDER = ("POR", "DIF", "CEN", "ATT")


class AuctionSession(Base):
    __tablename__ = "auction_sessions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    league_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("fantasy_leagues.id", ondelete="CASCADE"), nullable=False
    )
    status: Mapped[str] = mapped_column(String(20), default="idle", nullable=False)
    session_type: Mapped[str] = mapped_column(String(20), default="initial", nullable=False)
    scheduled_start: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    release_deadline: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    current_player_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("players.id", ondelete="SET NULL"), nullable=True)
    current_min_bid: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=Decimal("1"), nullable=False)
    timer_ends_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    started_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    current_category: Mapped[str] = mapped_column(String(3), default="POR", nullable=False)
    current_turn_index: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    turn_order: Mapped[list] = mapped_column(JSONB, default=list, nullable=False)  # list of user_id (UUID str)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
