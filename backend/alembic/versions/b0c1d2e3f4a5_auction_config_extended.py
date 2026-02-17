"""Auction config extended: classic (bid_timer, min_raise, call_order, allow_nomination, pause) + sealed (rounds_count, reveal_bids, etc.) + base_price

Revision ID: b0c1d2e3f4a5
Revises: a9b0c1d2e3f4
Create Date: 2026-02-17

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "b0c1d2e3f4a5"
down_revision: Union[str, None] = "a9b0c1d2e3f4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("auction_config", sa.Column("base_price", sa.Integer(), server_default="1", nullable=False))
    op.add_column("auction_config", sa.Column("bid_timer_seconds", sa.Integer(), server_default="60", nullable=True))
    op.add_column("auction_config", sa.Column("min_raise", sa.Integer(), server_default="1", nullable=True))
    op.add_column("auction_config", sa.Column("call_order", sa.String(20), server_default="random", nullable=True))
    op.add_column("auction_config", sa.Column("allow_nomination", sa.Boolean(), server_default=sa.text("true"), nullable=True))
    op.add_column("auction_config", sa.Column("pause_between_players", sa.Integer(), server_default="10", nullable=True))
    op.add_column("auction_config", sa.Column("rounds_count", sa.Integer(), server_default="3", nullable=True))
    op.add_column("auction_config", sa.Column("reveal_bids", sa.Boolean(), server_default=sa.text("false"), nullable=True))
    op.add_column("auction_config", sa.Column("allow_same_player_bids", sa.Boolean(), server_default=sa.text("true"), nullable=True))
    op.add_column("auction_config", sa.Column("max_bids_per_round", sa.Integer(), server_default="5", nullable=True))
    op.add_column("auction_config", sa.Column("tie_breaker", sa.String(20), server_default="budget", nullable=True))


def downgrade() -> None:
    op.drop_column("auction_config", "tie_breaker")
    op.drop_column("auction_config", "max_bids_per_round")
    op.drop_column("auction_config", "allow_same_player_bids")
    op.drop_column("auction_config", "reveal_bids")
    op.drop_column("auction_config", "rounds_count")
    op.drop_column("auction_config", "pause_between_players")
    op.drop_column("auction_config", "allow_nomination")
    op.drop_column("auction_config", "call_order")
    op.drop_column("auction_config", "min_raise")
    op.drop_column("auction_config", "bid_timer_seconds")
    op.drop_column("auction_config", "base_price")
