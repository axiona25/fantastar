"""league asta_started

Revision ID: z8a9b0c1d2e3
Revises: y7z8a9b0c1d2
Create Date: 2026-02-17

Aggiunge asta_started a fantasy_leagues per abilitare pulsante Asta in La mia Squadra.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "z8a9b0c1d2e3"
down_revision: Union[str, None] = "y7z8a9b0c1d2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "fantasy_leagues",
        sa.Column("asta_started", sa.Boolean(), nullable=False, server_default=sa.false()),
    )


def downgrade() -> None:
    op.drop_column("fantasy_leagues", "asta_started")
