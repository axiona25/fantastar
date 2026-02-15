"""add_league_members

Revision ID: k1f8g9h0j0
Revises: j0e6f7g8h9i9
Create Date: 2026-02-16

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "k1f8g9h0j0"
down_revision: Union[str, None] = "j0e6f7g8h9i9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "fantasy_league_members",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("league_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("role", sa.String(length=20), server_default="member", nullable=True),
        sa.Column("team_name", sa.String(length=100), nullable=True),
        sa.Column("budget_remaining", sa.Numeric(precision=10, scale=2), server_default=sa.text("500.00"), nullable=True),
        sa.Column("joined_at", sa.DateTime(), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["league_id"], ["fantasy_leagues.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("league_id", "user_id", name="uq_fantasy_league_members_league_user"),
    )

    op.add_column(
        "fantasy_rosters",
        sa.Column("league_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_fantasy_rosters_league_id",
        "fantasy_rosters",
        "fantasy_leagues",
        ["league_id"],
        ["id"],
        ondelete="CASCADE",
    )

    # Seed: add r.amoroso80@gmail.com as admin of league 'Fantastar'
    op.execute(sa.text("""
        INSERT INTO fantasy_league_members (league_id, user_id, role, team_name, budget_remaining)
        SELECT fl.id, u.id, 'admin', 'Longobarda', 500.00
        FROM fantasy_leagues fl, users u
        WHERE fl.name = 'Fantastar' AND u.email = 'r.amoroso80@gmail.com'
        ON CONFLICT ON CONSTRAINT uq_fantasy_league_members_league_user DO NOTHING
    """))


def downgrade() -> None:
    op.drop_constraint("fk_fantasy_rosters_league_id", "fantasy_rosters", type_="foreignkey")
    op.drop_column("fantasy_rosters", "league_id")
    op.drop_table("fantasy_league_members")
