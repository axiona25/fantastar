"""Membro di una lega fantasy: league_id, user_id, role, status, team_name, budget_remaining."""
import uuid
from datetime import datetime
from decimal import Decimal
from sqlalchemy import String, Integer, Numeric, DateTime, ForeignKey, Text, Boolean, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class FantasyLeagueMember(Base):
    __tablename__ = "fantasy_league_members"
    __table_args__ = (UniqueConstraint("league_id", "user_id", name="uq_fantasy_league_members_league_user"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    league_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("fantasy_leagues.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    role: Mapped[str] = mapped_column(String(20), default="member")  # 'admin' | 'member'
    status: Mapped[str] = mapped_column(String(10), default="active", nullable=False)  # 'active' | 'blocked' | 'kicked'
    team_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    budget_remaining: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=500)
    joined_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    blocked_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    blocked_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
