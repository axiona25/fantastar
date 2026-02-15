"""auction turns: current_category, current_turn_index, turn_order

Revision ID: m5n6o7p8q9r0
Revises: l2g0h1i2j3k4
Create Date: 2026-02-16

Asta a turni: categoria (POR/DIF/CEN/ATT), indice turno, ordine partecipanti.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "m5n6o7p8q9r0"
down_revision: Union[str, None] = "l2g0h1i2j3k4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "auction_sessions",
        sa.Column("current_category", sa.String(3), server_default="POR", nullable=False),
    )
    op.add_column(
        "auction_sessions",
        sa.Column("current_turn_index", sa.Integer(), server_default="0", nullable=False),
    )
    op.add_column(
        "auction_sessions",
        sa.Column("turn_order", postgresql.JSONB(astext_type=sa.Text()), server_default="[]", nullable=False),
    )


def downgrade() -> None:
    op.drop_column("auction_sessions", "turn_order")
    op.drop_column("auction_sessions", "current_turn_index")
    op.drop_column("auction_sessions", "current_category")
