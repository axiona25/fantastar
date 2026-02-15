from datetime import datetime
from decimal import Decimal
from sqlalchemy import String, Integer, Boolean, Numeric, DateTime, ForeignKey, Index, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class PlayerStats(Base):
    __tablename__ = "player_stats"
    __table_args__ = (
        UniqueConstraint("player_id", "match_id", name="idx_player_stats_unique"),
        Index("idx_player_stats_match", "match_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    player_id: Mapped[int] = mapped_column(Integer, ForeignKey("players.id"), nullable=False)
    match_id: Mapped[int] = mapped_column(Integer, ForeignKey("matches.id"), nullable=False)
    minutes_played: Mapped[int] = mapped_column(Integer, default=0)
    rating: Mapped[Decimal | None] = mapped_column(Numeric(3, 1), nullable=True)
    goals: Mapped[int] = mapped_column(Integer, default=0)
    assists: Mapped[int] = mapped_column(Integer, default=0)
    expected_goals: Mapped[Decimal | None] = mapped_column(Numeric(4, 2), nullable=True)
    expected_assists: Mapped[Decimal | None] = mapped_column(Numeric(4, 2), nullable=True)
    total_shots: Mapped[int] = mapped_column(Integer, default=0)
    shots_on_target: Mapped[int] = mapped_column(Integer, default=0)
    total_passes: Mapped[int] = mapped_column(Integer, default=0)
    accurate_passes: Mapped[int] = mapped_column(Integer, default=0)
    key_passes: Mapped[int] = mapped_column(Integer, default=0)
    total_crosses: Mapped[int] = mapped_column(Integer, default=0)
    accurate_crosses: Mapped[int] = mapped_column(Integer, default=0)
    total_long_balls: Mapped[int] = mapped_column(Integer, default=0)
    accurate_long_balls: Mapped[int] = mapped_column(Integer, default=0)
    total_tackles: Mapped[int] = mapped_column(Integer, default=0)
    tackles_won: Mapped[int] = mapped_column(Integer, default=0)
    interceptions: Mapped[int] = mapped_column(Integer, default=0)
    clearances: Mapped[int] = mapped_column(Integer, default=0)
    saves: Mapped[int] = mapped_column(Integer, default=0)
    clean_sheet: Mapped[bool] = mapped_column(Boolean, default=False)
    source: Mapped[str] = mapped_column(String(20), default="bzzoiro")
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
