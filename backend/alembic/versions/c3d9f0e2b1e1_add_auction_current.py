"""add_auction_current

Revision ID: c3d9f0e2b1e1
Revises: b2c8e7f1a0d0
Create Date: 2026-02-13

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "c3d9f0e2b1e1"
down_revision: Union[str, None] = "b2c8e7f1a0d0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
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


def downgrade() -> None:
    op.drop_table("auction_current")
