"""add_fcm_tokens

Revision ID: g7b3c4d5e6f6
Revises: f6a2b3c4d5e5
Create Date: 2026-02-14

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "g7b3c4d5e6f6"
down_revision: Union[str, None] = "f6a2b3c4d5e5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "fcm_tokens",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("token", sa.String(500), nullable=False),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("user_id", "token", name="uq_fcm_user_token"),
    )
    op.create_index("idx_fcm_tokens_user", "fcm_tokens", ["user_id"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_fcm_tokens_user", table_name="fcm_tokens")
    op.drop_table("fcm_tokens")
