import uuid
from sqlalchemy import Integer, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class FantasyCalendar(Base):
    __tablename__ = "fantasy_calendar"
    __table_args__ = (UniqueConstraint("league_id", "matchday", "home_team_id", name="uq_fantasy_calendar_league_matchday_home"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    league_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("fantasy_leagues.id", ondelete="CASCADE"), nullable=False)
    matchday: Mapped[int] = mapped_column(Integer, nullable=False)
    home_team_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("fantasy_teams.id"), nullable=False)
    away_team_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("fantasy_teams.id"), nullable=False)
