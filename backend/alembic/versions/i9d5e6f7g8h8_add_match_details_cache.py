"""add_match_details_cache

Revision ID: i9d5e6f7g8h8
Revises: h8c4d5e6f7g7
Create Date: 2026-02-15

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "i9d5e6f7g8h8"
down_revision: Union[str, None] = "h8c4d5e6f7g7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "match_details_cache",
        sa.Column("match_id", sa.Integer(), nullable=False),
        sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("fetched_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["match_id"], ["matches.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("match_id"),
    )


def downgrade() -> None:
    op.drop_table("match_details_cache")
