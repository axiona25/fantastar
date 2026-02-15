"""add_auction_sessions

Revision ID: l2g0h1i2j3k4
Revises: k1f8g9h0j0
Create Date: 2026-02-16

Auction module: auction_sessions, auction_bids (session-based), auction_results.
Replaces auction_current and legacy auction_bids.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "l2g0h1i2j3k4"
down_revision: Union[str, None] = "k1f8g9h0j0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Drop old auction tables (replaced by session-based flow)
    op.drop_table("auction_bids")
    op.drop_table("auction_current")

    op.create_table(
        "auction_sessions",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("league_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("status", sa.String(20), server_default="idle", nullable=False),
        sa.Column("current_player_id", sa.Integer(), nullable=True),
        sa.Column("current_min_bid", sa.Numeric(10, 2), server_default=sa.text("1"), nullable=False),
        sa.Column("timer_ends_at", sa.DateTime(), nullable=True),
        sa.Column("started_by", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["league_id"], ["fantasy_leagues.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["current_player_id"], ["players.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["started_by"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_auction_sessions_league", "auction_sessions", ["league_id"], unique=False)

    op.create_table(
        "auction_bids",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("session_id", sa.Integer(), nullable=False),
        sa.Column("player_id", sa.Integer(), nullable=False),
        sa.Column("bidder_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("amount", sa.Numeric(10, 2), nullable=False),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["session_id"], ["auction_sessions.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["bidder_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_auction_bids_session", "auction_bids", ["session_id"], unique=False)

    op.create_table(
        "auction_results",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("session_id", sa.Integer(), nullable=False),
        sa.Column("player_id", sa.Integer(), nullable=False),
        sa.Column("winner_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("final_price", sa.Numeric(10, 2), nullable=False),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["session_id"], ["auction_sessions.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["winner_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_auction_results_session", "auction_results", ["session_id"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_auction_results_session", "auction_results")
    op.drop_table("auction_results")
    op.drop_index("idx_auction_bids_session", "auction_bids")
    op.drop_table("auction_bids")
    op.drop_index("idx_auction_sessions_league", "auction_sessions")
    op.drop_table("auction_sessions")

    # Restore old tables (minimal structure)
    op.create_table(
        "auction_current",
        sa.Column("league_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("player_id", sa.Integer(), nullable=False),
        sa.Column("highest_bid", sa.Numeric(10, 2), nullable=True, server_default="0"),
        sa.Column("highest_bidder_team_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("ends_at", sa.DateTime(), nullable=False),
        sa.Column("round_number", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["league_id"], ["fantasy_leagues.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"]),
        sa.ForeignKeyConstraint(["highest_bidder_team_id"], ["fantasy_teams.id"]),
        sa.PrimaryKeyConstraint("league_id"),
    )
    op.create_table(
        "auction_bids",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("league_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("fantasy_team_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("player_id", sa.Integer(), nullable=False),
        sa.Column("amount", sa.Numeric(10, 2), nullable=False),
        sa.Column("status", sa.String(20), server_default="PENDING", nullable=True),
        sa.Column("round_number", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["league_id"], ["fantasy_leagues.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["fantasy_team_id"], ["fantasy_teams.id"]),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_bids_league", "auction_bids", ["league_id"], unique=False)
    op.create_index("idx_bids_player", "auction_bids", ["player_id"], unique=False)
