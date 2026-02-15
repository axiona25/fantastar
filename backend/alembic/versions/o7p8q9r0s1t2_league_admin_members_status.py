"""league admin: members status/blocked, leagues soft delete

Revision ID: o7p8q9r0s1t2
Revises: n6o7p8q9r0s1
Create Date: 2026-02-16

- fantasy_league_members: status, blocked_at, blocked_reason
- fantasy_leagues: deleted_at, is_active (soft delete)
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "o7p8q9r0s1t2"
down_revision: Union[str, None] = "n6o7p8q9r0s1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # fantasy_league_members
    op.add_column(
        "fantasy_league_members",
        sa.Column("status", sa.String(10), server_default="active", nullable=False),
    )
    op.add_column(
        "fantasy_league_members",
        sa.Column("blocked_at", sa.DateTime(), nullable=True),
    )
    op.add_column(
        "fantasy_league_members",
        sa.Column("blocked_reason", sa.Text(), nullable=True),
    )
    op.create_check_constraint(
        "ck_fantasy_league_members_status",
        "fantasy_league_members",
        "status IN ('active', 'blocked', 'kicked')",
    )
    # fantasy_leagues
    op.add_column(
        "fantasy_leagues",
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
    )
    op.add_column(
        "fantasy_leagues",
        sa.Column("is_active", sa.Boolean(), server_default=sa.true(), nullable=False),
    )


def downgrade() -> None:
    op.drop_column("fantasy_leagues", "is_active")
    op.drop_column("fantasy_leagues", "deleted_at")
    op.drop_constraint("ck_fantasy_league_members_status", "fantasy_league_members", type_="check")
    op.drop_column("fantasy_league_members", "blocked_reason")
    op.drop_column("fantasy_league_members", "blocked_at")
    op.drop_column("fantasy_league_members", "status")
