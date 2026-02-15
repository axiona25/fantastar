"""player_match_ratings: voti live e ufficiali per partita/giocatore

Revision ID: q9r0s1t2u3v4
Revises: p8q9r0s1t2u3
Create Date: 2026-02-16

- live_rating (algoritmo), gazzetta/corriere/tuttosport/media, fantasy_score
- bonus/malus fantacalcio (gol, assist, cartellini, clean_sheet, ecc.)
- UNIQUE(match_id, player_name, team)
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "q9r0s1t2u3v4"
down_revision: Union[str, None] = "p8q9r0s1t2u3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "player_match_ratings",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("match_id", sa.Integer(), nullable=False),
        sa.Column("player_name", sa.String(length=100), nullable=False),
        sa.Column("player_id", sa.Integer(), nullable=True),
        sa.Column("team", sa.String(length=100), nullable=False),
        sa.Column("live_rating", sa.Numeric(3, 1), nullable=True),
        sa.Column("gazzetta_rating", sa.Numeric(3, 1), nullable=True),
        sa.Column("corriere_rating", sa.Numeric(3, 1), nullable=True),
        sa.Column("tuttosport_rating", sa.Numeric(3, 1), nullable=True),
        sa.Column("media_rating", sa.Numeric(3, 1), nullable=True),
        sa.Column("goals", sa.Integer(), server_default="0", nullable=False),
        sa.Column("assists", sa.Integer(), server_default="0", nullable=False),
        sa.Column("own_goals", sa.Integer(), server_default="0", nullable=False),
        sa.Column("yellow_cards", sa.Integer(), server_default="0", nullable=False),
        sa.Column("red_cards", sa.Integer(), server_default="0", nullable=False),
        sa.Column("penalty_saved", sa.Integer(), server_default="0", nullable=False),
        sa.Column("penalty_missed", sa.Integer(), server_default="0", nullable=False),
        sa.Column("goals_conceded", sa.Integer(), server_default="0", nullable=False),
        sa.Column("minutes_played", sa.Integer(), server_default="0", nullable=False),
        sa.Column("clean_sheet", sa.Boolean(), server_default="false", nullable=False),
        sa.Column("fantasy_score", sa.Numeric(4, 1), nullable=True),
        sa.Column("source", sa.String(length=20), server_default=sa.text("'algorithm'"), nullable=False),
        sa.Column("is_final", sa.Boolean(), server_default="false", nullable=False),
        sa.Column("updated_at", sa.DateTime(), server_default=sa.text("NOW()"), nullable=False),
        sa.ForeignKeyConstraint(["match_id"], ["matches.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("match_id", "player_name", "team", name="uq_player_match_ratings_match_player_team"),
    )
    op.create_index("idx_player_match_ratings_match", "player_match_ratings", ["match_id"], unique=False)
    op.create_index("idx_player_match_ratings_player", "player_match_ratings", ["player_id"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_player_match_ratings_player", table_name="player_match_ratings")
    op.drop_index("idx_player_match_ratings_match", table_name="player_match_ratings")
    op.drop_table("player_match_ratings")
