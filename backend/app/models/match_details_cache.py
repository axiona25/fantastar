"""Cache dettaglio partita (eventi, formazioni, statistiche) da TheSportsDB."""
from datetime import datetime

from sqlalchemy import Integer, ForeignKey, DateTime, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class MatchDetailsCache(Base):
    """Cache payload dettaglio partita (eventi, lineups, statistics) da TheSportsDB."""
    __tablename__ = "match_details_cache"

    match_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("matches.id", ondelete="CASCADE"),
        primary_key=True,
    )
    payload: Mapped[dict] = mapped_column(JSONB, nullable=False)  # events, lineups, statistics
    fetched_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
