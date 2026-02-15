"""Svincolo giocatore: storico rilasci pre-asta o durante asta di riparazione."""
import uuid
from datetime import datetime

from sqlalchemy import Integer, DateTime, ForeignKey, String, func, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class PlayerRelease(Base):
    __tablename__ = "player_releases"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()")
    )
    league_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("fantasy_leagues.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    player_id: Mapped[int] = mapped_column(Integer, ForeignKey("players.id", ondelete="CASCADE"), nullable=False)
    auction_session_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("auction_sessions.id", ondelete="SET NULL"), nullable=True
    )
    original_price: Mapped[int] = mapped_column(Integer, nullable=False)
    refund_amount: Mapped[int] = mapped_column(Integer, nullable=False)
    released_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    release_phase: Mapped[str] = mapped_column(String(20), default="pre_auction", nullable=False)
