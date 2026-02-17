"""Asta random: auction_config, auction_turns, auction_turn_players, auction_turn_bids, auction_player_order

Revision ID: v4w5x6y7z8a9
Revises: u3v4w5x6y7z8
Create Date: 2026-02-16

Tabelle per asta random a busta chiusa: configurazione, turni, giocatori per turno, offerte segrete, ordine giocatori.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "v4w5x6y7z8a9"
down_revision: Union[str, None] = "u3v4w5x6y7z8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "auction_config",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("league_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("auction_type", sa.String(20), server_default="random", nullable=False),
        sa.Column("players_per_turn_p", sa.Integer(), server_default="3", nullable=False),
        sa.Column("players_per_turn_d", sa.Integer(), server_default="5", nullable=False),
        sa.Column("players_per_turn_c", sa.Integer(), server_default="5", nullable=False),
        sa.Column("players_per_turn_a", sa.Integer(), server_default="3", nullable=False),
        sa.Column("turn_duration_hours", sa.Integer(), server_default="24", nullable=False),
        sa.Column("budget_per_team", sa.Integer(), server_default="500", nullable=False),
        sa.Column("max_roster_size", sa.Integer(), server_default="25", nullable=False),
        sa.Column("min_goalkeepers", sa.Integer(), server_default="3", nullable=False),
        sa.Column("min_defenders", sa.Integer(), server_default="8", nullable=False),
        sa.Column("min_midfielders", sa.Integer(), server_default="8", nullable=False),
        sa.Column("min_attackers", sa.Integer(), server_default="6", nullable=False),
        sa.Column("status", sa.String(20), server_default="pending", nullable=False),
        sa.Column("current_role", sa.String(5), server_default="P", nullable=False),
        sa.Column("current_turn", sa.Integer(), server_default="0", nullable=False),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.Column("started_at", sa.DateTime(), nullable=True),
        sa.Column("completed_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["league_id"], ["fantasy_leagues.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_auction_config_league_id", "auction_config", ["league_id"], unique=True)

    op.create_table(
        "auction_turns",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("auction_config_id", sa.Integer(), nullable=False),
        sa.Column("turn_number", sa.Integer(), nullable=False),
        sa.Column("role", sa.String(5), nullable=False),
        sa.Column("status", sa.String(20), server_default="active", nullable=False),
        sa.Column("started_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.Column("completed_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["auction_config_id"], ["auction_config.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_auction_turns_config_expires", "auction_turns", ["auction_config_id", "status", "expires_at"])

    op.create_table(
        "auction_turn_players",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("auction_turn_id", sa.Integer(), nullable=False),
        sa.Column("player_id", sa.Integer(), nullable=False),
        sa.Column("winner_team_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("winning_bid", sa.Integer(), server_default="0", nullable=False),
        sa.Column("status", sa.String(20), server_default="available", nullable=False),
        sa.ForeignKeyConstraint(["auction_turn_id"], ["auction_turns.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["winner_team_id"], ["fantasy_teams.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "auction_turn_bids",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("auction_turn_player_id", sa.Integer(), nullable=False),
        sa.Column("fantasy_team_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("bid_amount", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["auction_turn_player_id"], ["auction_turn_players.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["fantasy_team_id"], ["fantasy_teams.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("auction_turn_player_id", "fantasy_team_id", name="uq_auction_turn_bids_turn_player_team"),
    )

    op.create_table(
        "auction_player_order",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("auction_config_id", sa.Integer(), nullable=False),
        sa.Column("player_id", sa.Integer(), nullable=False),
        sa.Column("role", sa.String(5), nullable=False),
        sa.Column("random_order", sa.Integer(), nullable=False),
        sa.Column("proposed", sa.Boolean(), server_default="false", nullable=False),
        sa.ForeignKeyConstraint(["auction_config_id"], ["auction_config.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_auction_player_order_config_role", "auction_player_order", ["auction_config_id", "role", "proposed"])


def downgrade() -> None:
    op.drop_table("auction_turn_bids")
    op.drop_table("auction_turn_players")
    op.drop_table("auction_turns")
    op.drop_table("auction_player_order")
    op.drop_table("auction_config")
