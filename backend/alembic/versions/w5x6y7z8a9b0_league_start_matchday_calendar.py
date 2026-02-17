"""league start_matchday, calendar_generated, league_matches

Revision ID: w5x6y7z8a9b0
Revises: v4w5x6y7z8a9
Create Date: 2026-02-16

Aggiunge a fantasy_leagues: start_matchday (default 1), calendar_generated (default false).
Crea tabella league_matches per calendario con round_number, serie_a_matchday, is_return_leg.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "w5x6y7z8a9b0"
down_revision: Union[str, None] = "v4w5x6y7z8a9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "fantasy_leagues",
        sa.Column("start_matchday", sa.Integer(), server_default="1", nullable=False),
    )
    op.add_column(
        "fantasy_leagues",
        sa.Column("calendar_generated", sa.Boolean(), server_default="false", nullable=False),
    )

    op.create_table(
        "league_matches",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("league_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("round_number", sa.Integer(), nullable=False),
        sa.Column("serie_a_matchday", sa.Integer(), nullable=False),
        sa.Column("home_team_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("away_team_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("home_score", sa.REAL(), nullable=True),
        sa.Column("away_score", sa.REAL(), nullable=True),
        sa.Column("is_return_leg", sa.Boolean(), server_default="false", nullable=False),
        sa.Column("played", sa.Boolean(), server_default="false", nullable=False),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["league_id"], ["fantasy_leagues.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["home_team_id"], ["fantasy_teams.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["away_team_id"], ["fantasy_teams.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_league_matches_league", "league_matches", ["league_id"], unique=False)
    op.create_index("idx_league_matches_round", "league_matches", ["league_id", "round_number"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_league_matches_round", table_name="league_matches")
    op.drop_index("idx_league_matches_league", table_name="league_matches")
    op.drop_table("league_matches")
    op.drop_column("fantasy_leagues", "calendar_generated")
    op.drop_column("fantasy_leagues", "start_matchday")
