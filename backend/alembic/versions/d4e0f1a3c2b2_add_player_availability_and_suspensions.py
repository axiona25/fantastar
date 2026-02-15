"""add_player_availability_and_suspensions

Revision ID: d4e0f1a3c2b2
Revises: c3d9f0e2b1e1
Create Date: 2026-02-13

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "d4e0f1a3c2b2"
down_revision: Union[str, None] = "c3d9f0e2b1e1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("players", sa.Column("availability_status", sa.String(length=20), nullable=True, server_default="AVAILABLE"))
    op.add_column("players", sa.Column("availability_detail", sa.String(length=200), nullable=True))
    op.add_column("players", sa.Column("availability_return_date", sa.Date(), nullable=True))
    op.add_column("players", sa.Column("availability_updated_at", sa.DateTime(), nullable=True))
    op.create_table(
        "player_suspensions",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("player_id", sa.Integer(), nullable=False),
        sa.Column("reason", sa.String(length=50), nullable=False),
        sa.Column("matchday_from", sa.Integer(), nullable=False),
        sa.Column("matchday_to", sa.Integer(), nullable=False),
        sa.Column("matches_count", sa.Integer(), nullable=True, server_default="1"),
        sa.Column("season", sa.String(length=10), nullable=True, server_default="2025"),
        sa.Column("is_active", sa.Boolean(), nullable=True, server_default="true"),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_suspensions_player_matchday", "player_suspensions", ["player_id", "matchday_from"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_suspensions_player_matchday", table_name="player_suspensions")
    op.drop_table("player_suspensions")
    op.drop_column("players", "availability_updated_at")
    op.drop_column("players", "availability_return_date")
    op.drop_column("players", "availability_detail")
    op.drop_column("players", "availability_status")
