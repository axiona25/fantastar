"""Proposta di scambio tra due squadre fantasy."""
import uuid
from datetime import datetime

from sqlalchemy import String, Integer, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class TradeProposal(Base):
    __tablename__ = "trade_proposals"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    league_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("fantasy_leagues.id", ondelete="CASCADE"), nullable=False)
    from_team_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("fantasy_teams.id"), nullable=False)
    to_team_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("fantasy_teams.id"), nullable=False)
    offer_player_ids: Mapped[list] = mapped_column(JSONB, nullable=False)  # [int]
    request_player_ids: Mapped[list] = mapped_column(JSONB, nullable=False)  # [int]
    status: Mapped[str] = mapped_column(String(20), default="PENDING")  # PENDING, ACCEPTED, REJECTED
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
