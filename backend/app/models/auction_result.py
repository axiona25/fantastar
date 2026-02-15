"""Risultato asta: giocatore aggiudicato a un utente per un prezzo."""
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, Integer, Numeric, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class AuctionResult(Base):
    __tablename__ = "auction_results"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    session_id: Mapped[int] = mapped_column(Integer, ForeignKey("auction_sessions.id", ondelete="CASCADE"), nullable=False)
    player_id: Mapped[int] = mapped_column(Integer, ForeignKey("players.id", ondelete="CASCADE"), nullable=False)
    winner_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    final_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    purchase_price: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    released: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    released_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    release_refund: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
