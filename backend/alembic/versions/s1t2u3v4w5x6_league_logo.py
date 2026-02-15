"""league_logo: fantasy_leagues.logo

Revision ID: s1t2u3v4w5x6
Revises: r0s1t2u3v4w5
Create Date: 2026-02-16

Aggiunge colonna logo alla tabella fantasy_leagues (nome icona default 'trophy').
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "s1t2u3v4w5x6"
down_revision: Union[str, None] = "r0s1t2u3v4w5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "fantasy_leagues",
        sa.Column("logo", sa.String(50), server_default="trophy", nullable=False),
    )


def downgrade() -> None:
    op.drop_column("fantasy_leagues", "logo")
