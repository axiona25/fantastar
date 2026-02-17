"""league auction_type (classic vs random)

Revision ID: a9b0c1d2e3f4
Revises: z8a9b0c1d2e3
Create Date: 2026-02-17

Salva il tipo di asta scelto in creazione lega: classic = rilanci competitivi, random = busta chiusa.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "a9b0c1d2e3f4"
down_revision: Union[str, None] = "z8a9b0c1d2e3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "fantasy_leagues",
        sa.Column("auction_type", sa.String(20), nullable=False, server_default="classic"),
    )


def downgrade() -> None:
    op.drop_column("fantasy_leagues", "auction_type")
