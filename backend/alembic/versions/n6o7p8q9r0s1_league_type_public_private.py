"""league_type and max_members: public vs private leagues

Revision ID: n6o7p8q9r0s1
Revises: m5n6o7p8q9r0
Create Date: 2026-02-16

- league_type: 'public' | 'private' (default 'private')
- max_members: NULL for public, 4-20 for private
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "n6o7p8q9r0s1"
down_revision: Union[str, None] = "m5n6o7p8q9r0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "fantasy_leagues",
        sa.Column("league_type", sa.String(10), server_default="private", nullable=False),
    )
    op.add_column(
        "fantasy_leagues",
        sa.Column("max_members", sa.Integer(), nullable=True),
    )
    op.create_check_constraint(
        "ck_fantasy_leagues_league_type",
        "fantasy_leagues",
        "league_type IN ('public', 'private')",
    )
    # Backfill: existing leagues are private, max_members = max_teams
    op.execute(
        "UPDATE fantasy_leagues SET max_members = max_teams WHERE league_type = 'private' AND max_members IS NULL"
    )
    # Seed: lega Fantastar esistente
    op.execute(
        "UPDATE fantasy_leagues SET league_type = 'private', max_members = 8 WHERE name = 'Fantastar'"
    )


def downgrade() -> None:
    op.drop_constraint("ck_fantasy_leagues_league_type", "fantasy_leagues", type_="check")
    op.drop_column("fantasy_leagues", "max_members")
    op.drop_column("fantasy_leagues", "league_type")
