"""auction_seats: sedie al tavolo asta live (join/leave, heartbeat)

Revision ID: c5d6e7f8a9b0
Revises: b0c1d2e3f4a5
Create Date: 2026-02-17

Tabella auction_seats: league_id, seat_number, team_id, joined_at, last_heartbeat.
Un team occupa una sedia; cleanup sedie con heartbeat > 30s.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "c5d6e7f8a9b0"
down_revision: Union[str, None] = "b0c1d2e3f4a5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "auction_seats",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("league_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("seat_number", sa.Integer(), nullable=False),
        sa.Column("team_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("joined_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.Column("last_heartbeat", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["league_id"], ["fantasy_leagues.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["team_id"], ["fantasy_teams.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("league_id", "seat_number", name="uq_auction_seats_league_seat"),
        sa.UniqueConstraint("league_id", "team_id", name="uq_auction_seats_league_team"),
    )
    op.create_index("ix_auction_seats_league_id", "auction_seats", ["league_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_auction_seats_league_id", table_name="auction_seats")
    op.drop_table("auction_seats")
