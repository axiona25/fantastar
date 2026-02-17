"""serie_a_postponed: partite Serie A rinviate per 6 politico

Revision ID: x6y7z8a9b0c1
Revises: w5x6y7z8a9b0
Create Date: 2026-02-16

Tabella per tracciare partite Serie A rinviate: in quella giornata
i giocatori delle squadre coinvolte prendono 6 politico.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "x6y7z8a9b0c1"
down_revision: Union[str, None] = "w5x6y7z8a9b0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "serie_a_postponed",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("matchday", sa.Integer(), nullable=False),
        sa.Column("home_team_id", sa.Integer(), nullable=False),
        sa.Column("away_team_id", sa.Integer(), nullable=False),
        sa.Column("original_date", sa.DateTime(), nullable=True),
        sa.Column("postponed_to", sa.DateTime(), nullable=True),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["home_team_id"], ["real_teams.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["away_team_id"], ["real_teams.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("matchday", "home_team_id", "away_team_id", name="uq_serie_a_postponed_matchday_teams"),
    )
    op.create_index("idx_postponed_matchday", "serie_a_postponed", ["matchday"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_postponed_matchday", table_name="serie_a_postponed")
    op.drop_table("serie_a_postponed")
