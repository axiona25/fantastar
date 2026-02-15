"""repair_auction_fields: session_type, scheduled_start, release_deadline; auction_results released; player_releases

Revision ID: r0s1t2u3v4w5
Revises: q9r0s1t2u3v4
Create Date: 2026-02-16

Asta di riparazione: nuovi campi auction_sessions, auction_results, tabella player_releases.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "r0s1t2u3v4w5"
down_revision: Union[str, None] = "q9r0s1t2u3v4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # auction_sessions: session_type, scheduled_start, release_deadline
    op.add_column(
        "auction_sessions",
        sa.Column("session_type", sa.String(20), server_default="initial", nullable=False),
    )
    op.add_column(
        "auction_sessions",
        sa.Column("scheduled_start", sa.DateTime(), nullable=True),
    )
    op.add_column(
        "auction_sessions",
        sa.Column("release_deadline", sa.DateTime(), nullable=True),
    )
    op.create_index(
        "idx_auction_sessions_type",
        "auction_sessions",
        ["session_type"],
        unique=False,
    )

    # auction_results: purchase_price, released, released_at, release_refund
    op.add_column(
        "auction_results",
        sa.Column("purchase_price", sa.Integer(), server_default="0", nullable=False),
    )
    op.add_column(
        "auction_results",
        sa.Column("released", sa.Boolean(), server_default=sa.text("false"), nullable=False),
    )
    op.add_column(
        "auction_results",
        sa.Column("released_at", sa.DateTime(), nullable=True),
    )
    op.add_column(
        "auction_results",
        sa.Column("release_refund", sa.Integer(), server_default="0", nullable=False),
    )

    # player_releases
    op.create_table(
        "player_releases",
        sa.Column("id", postgresql.UUID(as_uuid=True), server_default=sa.text("gen_random_uuid()"), nullable=False),
        sa.Column("league_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("player_id", sa.Integer(), nullable=False),
        sa.Column("auction_session_id", sa.Integer(), nullable=True),
        sa.Column("original_price", sa.Integer(), nullable=False),
        sa.Column("refund_amount", sa.Integer(), nullable=False),
        sa.Column("released_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.Column("release_phase", sa.String(20), server_default="pre_auction", nullable=False),
        sa.ForeignKeyConstraint(["league_id"], ["fantasy_leagues.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["auction_session_id"], ["auction_sessions.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_player_releases_league", "player_releases", ["league_id"], unique=False)
    op.create_index("idx_player_releases_user", "player_releases", ["league_id", "user_id"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_player_releases_user", "player_releases")
    op.drop_index("idx_player_releases_league", "player_releases")
    op.drop_table("player_releases")

    op.drop_column("auction_results", "release_refund")
    op.drop_column("auction_results", "released_at")
    op.drop_column("auction_results", "released")
    op.drop_column("auction_results", "purchase_price")

    op.drop_index("idx_auction_sessions_type", "auction_sessions")
    op.drop_column("auction_sessions", "release_deadline")
    op.drop_column("auction_sessions", "scheduled_start")
    op.drop_column("auction_sessions", "session_type")
