"""Ordine randomizzato dei giocatori per asta random, per ruolo."""
from sqlalchemy import Integer, Boolean, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class AuctionPlayerOrder(Base):
    __tablename__ = "auction_player_order"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    auction_config_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("auction_config.id", ondelete="CASCADE"), nullable=False
    )
    player_id: Mapped[int] = mapped_column(Integer, ForeignKey("players.id"), nullable=False)
    role: Mapped[str] = mapped_column(String(5), nullable=False)
    random_order: Mapped[int] = mapped_column(Integer, nullable=False)
    proposed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
