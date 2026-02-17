"""Modello partite Serie A rinviate: per la regola 6 politico."""
from datetime import datetime
from sqlalchemy import Integer, Text, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class SerieAPostponed(Base):
    __tablename__ = "serie_a_postponed"
    __table_args__ = (
        UniqueConstraint("matchday", "home_team_id", "away_team_id", name="uq_serie_a_postponed_matchday_teams"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    matchday: Mapped[int] = mapped_column(Integer, nullable=False)
    home_team_id: Mapped[int] = mapped_column(Integer, ForeignKey("real_teams.id", ondelete="CASCADE"), nullable=False)
    away_team_id: Mapped[int] = mapped_column(Integer, ForeignKey("real_teams.id", ondelete="CASCADE"), nullable=False)
    original_date: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    postponed_to: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime | None] = mapped_column(DateTime, server_default=func.now(), nullable=True)
