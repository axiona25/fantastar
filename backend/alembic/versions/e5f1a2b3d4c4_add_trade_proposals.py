"""add_trade_proposals

Revision ID: e5f1a2b3d4c4
Revises: d4e0f1a3c2b2
Create Date: 2026-02-13

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "e5f1a2b3d4c4"
down_revision: Union[str, None] = "d4e0f1a3c2b2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "trade_proposals",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("league_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("from_team_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("to_team_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("offer_player_ids", postgresql.JSONB(), nullable=False),
        sa.Column("request_player_ids", postgresql.JSONB(), nullable=False),
        sa.Column("status", sa.String(20), nullable=True, server_default="PENDING"),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["league_id"], ["fantasy_leagues.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["from_team_id"], ["fantasy_teams.id"]),
        sa.ForeignKeyConstraint(["to_team_id"], ["fantasy_teams.id"]),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("trade_proposals")
