"""Configurazione asta per lega: parametri rosa, classica (rilancio) o busta chiusa."""
import uuid
from datetime import datetime

from sqlalchemy import Boolean, Integer, String, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class AuctionConfig(Base):
    __tablename__ = "auction_config"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    league_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("fantasy_leagues.id", ondelete="CASCADE"), nullable=False
    )
    auction_type: Mapped[str] = mapped_column(String(20), default="classic", nullable=False)
    # Comuni (rosa)
    budget_per_team: Mapped[int] = mapped_column(Integer, default=500, nullable=False)
    max_roster_size: Mapped[int] = mapped_column(Integer, default=25, nullable=False)
    min_goalkeepers: Mapped[int] = mapped_column(Integer, default=3, nullable=False)
    min_defenders: Mapped[int] = mapped_column(Integer, default=8, nullable=False)
    min_midfielders: Mapped[int] = mapped_column(Integer, default=8, nullable=False)
    min_attackers: Mapped[int] = mapped_column(Integer, default=6, nullable=False)
    base_price: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    # Asta classica (rilancio)
    bid_timer_seconds: Mapped[int | None] = mapped_column(Integer, default=60, nullable=True)
    min_raise: Mapped[int | None] = mapped_column(Integer, default=1, nullable=True)
    call_order: Mapped[str | None] = mapped_column(String(20), default="random", nullable=True)
    allow_nomination: Mapped[bool | None] = mapped_column(Boolean, default=True, nullable=True)
    pause_between_players: Mapped[int | None] = mapped_column(Integer, default=10, nullable=True)
    # Busta chiusa (random)
    players_per_turn_p: Mapped[int] = mapped_column(Integer, default=3, nullable=False)
    players_per_turn_d: Mapped[int] = mapped_column(Integer, default=5, nullable=False)
    players_per_turn_c: Mapped[int] = mapped_column(Integer, default=5, nullable=False)
    players_per_turn_a: Mapped[int] = mapped_column(Integer, default=3, nullable=False)
    turn_duration_hours: Mapped[int] = mapped_column(Integer, default=24, nullable=False)
    rounds_count: Mapped[int | None] = mapped_column(Integer, default=3, nullable=True)
    reveal_bids: Mapped[bool | None] = mapped_column(Boolean, default=False, nullable=True)
    allow_same_player_bids: Mapped[bool | None] = mapped_column(Boolean, default=True, nullable=True)
    max_bids_per_round: Mapped[int | None] = mapped_column(Integer, default=5, nullable=True)
    tie_breaker: Mapped[str | None] = mapped_column(String(20), default="budget", nullable=True)
    # Stato
    status: Mapped[str] = mapped_column(String(20), default="pending", nullable=False)
    current_role: Mapped[str] = mapped_column(String(5), default="P", nullable=False)
    current_turn: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    started_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
