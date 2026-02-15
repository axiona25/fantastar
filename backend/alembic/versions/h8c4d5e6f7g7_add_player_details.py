"""add_player_details

Revision ID: h8c4d5e6f7g7
Revises: g7b3c4d5e6f6
Create Date: 2026-02-14

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "h8c4d5e6f7g7"
down_revision: Union[str, None] = "g7b3c4d5e6f6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("players", sa.Column("position_detail", sa.String(length=100), nullable=True))
    op.add_column("players", sa.Column("height", sa.String(length=50), nullable=True))
    op.add_column("players", sa.Column("weight", sa.String(length=50), nullable=True))
    op.add_column("players", sa.Column("description", sa.Text(), nullable=True))
    op.add_column("players", sa.Column("birth_place", sa.String(length=200), nullable=True))


def downgrade() -> None:
    op.drop_column("players", "birth_place")
    op.drop_column("players", "description")
    op.drop_column("players", "weight")
    op.drop_column("players", "height")
    op.drop_column("players", "position_detail")
