"""Voti live (algoritmo) e ufficiali (Gazzetta, ecc.) per giocatore/partita."""
from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, Integer, Numeric, String, func, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class PlayerMatchRating(Base):
    __tablename__ = "player_match_ratings"
    __table_args__ = (
        Index("idx_player_match_ratings_match", "match_id"),
        Index("idx_player_match_ratings_player", "player_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    match_id: Mapped[int] = mapped_column(Integer, ForeignKey("matches.id", ondelete="CASCADE"), nullable=False)
    player_name: Mapped[str] = mapped_column(String(100), nullable=False)
    player_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("players.id", ondelete="SET NULL"), nullable=True)
    team: Mapped[str] = mapped_column(String(100), nullable=False)

    live_rating: Mapped[Decimal | None] = mapped_column(Numeric(3, 1), nullable=True)
    gazzetta_rating: Mapped[Decimal | None] = mapped_column(Numeric(3, 1), nullable=True)
    corriere_rating: Mapped[Decimal | None] = mapped_column(Numeric(3, 1), nullable=True)
    tuttosport_rating: Mapped[Decimal | None] = mapped_column(Numeric(3, 1), nullable=True)
    media_rating: Mapped[Decimal | None] = mapped_column(Numeric(3, 1), nullable=True)

    goals: Mapped[int] = mapped_column(Integer, server_default="0", nullable=False)
    assists: Mapped[int] = mapped_column(Integer, server_default="0", nullable=False)
    own_goals: Mapped[int] = mapped_column(Integer, server_default="0", nullable=False)
    yellow_cards: Mapped[int] = mapped_column(Integer, server_default="0", nullable=False)
    red_cards: Mapped[int] = mapped_column(Integer, server_default="0", nullable=False)
    penalty_saved: Mapped[int] = mapped_column(Integer, server_default="0", nullable=False)
    penalty_missed: Mapped[int] = mapped_column(Integer, server_default="0", nullable=False)
    goals_conceded: Mapped[int] = mapped_column(Integer, server_default="0", nullable=False)
    minutes_played: Mapped[int] = mapped_column(Integer, server_default="0", nullable=False)
    clean_sheet: Mapped[bool] = mapped_column(Boolean, server_default="false", nullable=False)

    fantasy_score: Mapped[Decimal | None] = mapped_column(Numeric(4, 1), nullable=True)
    source: Mapped[str] = mapped_column(String(20), server_default=text("'algorithm'"), nullable=False)
    is_final: Mapped[bool] = mapped_column(Boolean, server_default="false", nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)
