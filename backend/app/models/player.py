from datetime import datetime, date
from decimal import Decimal
from sqlalchemy import String, Integer, Boolean, Date, DateTime, Numeric, ForeignKey, Index, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base


class Player(Base):
    __tablename__ = "players"
    __table_args__ = (
        Index("idx_players_team", "real_team_id"),
        Index("idx_players_position", "position"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    external_id: Mapped[int | None] = mapped_column(Integer, unique=True, nullable=True)
    real_team_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("real_teams.id"), nullable=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    first_name: Mapped[str | None] = mapped_column(String(50), nullable=True)
    last_name: Mapped[str | None] = mapped_column(String(50), nullable=True)
    position: Mapped[str] = mapped_column(String(3), nullable=False)  # POR, DIF, CEN, ATT
    position_detail: Mapped[str | None] = mapped_column(String(100), nullable=True)  # es. "Centre-Back"
    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)
    nationality: Mapped[str | None] = mapped_column(String(50), nullable=True)
    shirt_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
    photo_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    photo_local: Mapped[str | None] = mapped_column(String(255), nullable=True)
    cutout_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    cutout_local: Mapped[str | None] = mapped_column(String(255), nullable=True)
    avatar_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    thesportsdb_id: Mapped[str | None] = mapped_column(String(20), nullable=True)
    bzzoiro_id: Mapped[str | None] = mapped_column(String(20), nullable=True)
    initial_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=1)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    # Dettaglio scheda (da TheSportsDB o manuale)
    height: Mapped[str | None] = mapped_column(String(50), nullable=True)  # es. "1.85 m"
    weight: Mapped[str | None] = mapped_column(String(50), nullable=True)  # es. "78 kg"
    description: Mapped[str | None] = mapped_column(Text, nullable=True)  # biografia
    birth_place: Mapped[str | None] = mapped_column(String(200), nullable=True)
    # Stato disponibilità (Task 06B)
    availability_status: Mapped[str] = mapped_column(String(20), default="AVAILABLE")
    availability_detail: Mapped[str | None] = mapped_column(String(200), nullable=True)
    availability_return_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    availability_updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
