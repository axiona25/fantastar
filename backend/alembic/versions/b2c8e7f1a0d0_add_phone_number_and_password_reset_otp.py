"""add_phone_number_and_password_reset_otp

Revision ID: b2c8e7f1a0d0
Revises: e54babdf6aab
Create Date: 2026-02-13

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "b2c8e7f1a0d0"
down_revision: Union[str, None] = "e54babdf6aab"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("phone_number", sa.String(length=20), nullable=True))

    op.create_table(
        "password_reset_otp",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("otp_code", sa.String(length=6), nullable=False),
        sa.Column("firebase_session", sa.String(length=500), nullable=True),
        sa.Column("is_verified", sa.Boolean(), nullable=True, server_default="false"),
        sa.Column("is_used", sa.Boolean(), nullable=True, server_default="false"),
        sa.Column("attempts", sa.Integer(), nullable=True, server_default="0"),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("password_reset_otp")
    op.drop_column("users", "phone_number")
