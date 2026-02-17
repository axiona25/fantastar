"""fantasy_teams coach_name, coach_avatar_url, is_configured

Revision ID: y7z8a9b0c1d2
Revises: x6y7z8a9b0c1
Create Date: 2026-02-16

Aggiunge colonne per Crea Squadra: coach_name, coach_avatar_url, is_configured.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "y7z8a9b0c1d2"
down_revision: Union[str, None] = "x6y7z8a9b0c1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "fantasy_teams",
        sa.Column("coach_name", sa.String(100), nullable=True),
    )
    op.add_column(
        "fantasy_teams",
        sa.Column("coach_avatar_url", sa.String(500), nullable=True),
    )
    op.add_column(
        "fantasy_teams",
        sa.Column("is_configured", sa.Boolean(), nullable=False, server_default=sa.false()),
    )


def downgrade() -> None:
    op.drop_column("fantasy_teams", "is_configured")
    op.drop_column("fantasy_teams", "coach_avatar_url")
    op.drop_column("fantasy_teams", "coach_name")
