"""players avatar_url

Revision ID: t2u3v4w5x6y7
Revises: s1t2u3v4w5x6
Create Date: 2026-02-16

Aggiunge colonna avatar_url alla tabella players (path avatar Disney/cartoon).
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "t2u3v4w5x6y7"
down_revision: Union[str, None] = "s1t2u3v4w5x6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "players",
        sa.Column("avatar_url", sa.String(500), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("players", "avatar_url")
