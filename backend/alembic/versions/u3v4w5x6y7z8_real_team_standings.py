"""real_team_standings

Revision ID: u3v4w5x6y7z8
Revises: t2u3v4w5x6y7
Create Date: 2026-02-16

Tabella classifica Serie A per stagione (rank, punti, gol, ecc.).
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "u3v4w5x6y7z8"
down_revision: Union[str, None] = "t2u3v4w5x6y7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "real_team_standings",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("season_year", sa.Integer(), nullable=False),
        sa.Column("real_team_id", sa.Integer(), nullable=False),
        sa.Column("rank", sa.Integer(), nullable=False),
        sa.Column("games_played", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("wins", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("draws", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("losses", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("goals_for", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("goals_against", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("goal_difference", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("points", sa.Integer(), nullable=False, server_default="0"),
        sa.ForeignKeyConstraint(["real_team_id"], ["real_teams.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("season_year", "real_team_id", name="uq_real_team_standings_season_team"),
    )
    op.create_index("idx_real_team_standings_season", "real_team_standings", ["season_year"], unique=False)
    op.create_index("idx_real_team_standings_team", "real_team_standings", ["real_team_id"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_real_team_standings_team", table_name="real_team_standings")
    op.drop_index("idx_real_team_standings_season", table_name="real_team_standings")
    op.drop_table("real_team_standings")
