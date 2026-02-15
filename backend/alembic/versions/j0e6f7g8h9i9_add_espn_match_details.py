"""add_espn_match_details

Revision ID: j0e6f7g8h9i9
Revises: i9d5e6f7g8h8
Create Date: 2026-02-16

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "j0e6f7g8h9i9"
down_revision: Union[str, None] = "i9d5e6f7g8h8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("matches", sa.Column("espn_event_id", sa.String(length=20), nullable=True))


def downgrade() -> None:
    op.drop_column("matches", "espn_event_id")
