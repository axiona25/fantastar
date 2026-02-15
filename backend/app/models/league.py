import uuid
from datetime import datetime
from decimal import Decimal
from sqlalchemy import Boolean, String, Integer, Numeric, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class FantasyLeague(Base):
    __tablename__ = "fantasy_leagues"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    logo: Mapped[str] = mapped_column(String(50), default="trophy", nullable=False)
    admin_user_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    invite_code: Mapped[str | None] = mapped_column(String(20), unique=True, nullable=True)
    max_teams: Mapped[int] = mapped_column(Integer, default=10)
    league_type: Mapped[str] = mapped_column(String(10), default="private", nullable=False)  # 'public' | 'private'
    max_members: Mapped[int | None] = mapped_column(Integer, nullable=True)  # NULL public, 4-20 private
    budget: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=500)
    scoring_type: Mapped[str] = mapped_column(String(20), default="EVENT_BASED")
    status: Mapped[str] = mapped_column(String(20), default="DRAFT")
    season: Mapped[str] = mapped_column(String(10), default="2025")
    goal_threshold: Mapped[Decimal] = mapped_column(Numeric(5, 1), default=66)
    goal_step: Mapped[Decimal] = mapped_column(Numeric(5, 1), default=8)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    parent_league_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("fantasy_leagues.id", ondelete="SET NULL"), nullable=True
    )
    auto_created: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
