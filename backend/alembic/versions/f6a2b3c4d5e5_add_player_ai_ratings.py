"""add_player_ai_ratings

Revision ID: f6a2b3c4d5e5
Revises: e5f1a2b3d4c4
Create Date: 2026-02-13

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "f6a2b3c4d5e5"
down_revision: Union[str, None] = "e5f1a2b3d4c4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "player_ai_ratings",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("player_id", sa.Integer(), nullable=False),
        sa.Column("match_id", sa.Integer(), nullable=False),
        sa.Column("minute", sa.Integer(), nullable=False),
        sa.Column("rating", sa.Float(), nullable=False),
        sa.Column("trend", sa.String(10), server_default="stable", nullable=True),
        sa.Column("mentions", sa.Integer(), server_default="0", nullable=True),
        sa.Column("key_actions", sa.JSON(), nullable=True),
        sa.Column("source", sa.String(20), server_default="local", nullable=True),
        sa.Column("is_final", sa.Boolean(), server_default="false", nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["match_id"], ["matches.id"], ondelete="CASCADE"),
    )
    op.create_index("idx_player_ai_ratings_match", "player_ai_ratings", ["match_id"], unique=False)
    op.create_index("idx_player_ai_ratings_player_match", "player_ai_ratings", ["player_id", "match_id"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_player_ai_ratings_player_match", table_name="player_ai_ratings")
    op.drop_index("idx_player_ai_ratings_match", table_name="player_ai_ratings")
    op.drop_table("player_ai_ratings")
