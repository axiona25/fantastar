"""public league auto-split: parent_league_id, auto_created

Revision ID: p8q9r0s1t2u3
Revises: o7p8q9r0s1t2
Create Date: 2026-02-16

- parent_league_id: FK to fantasy_leagues.id (NULL = root)
- auto_created: True for auto-created child leagues (1000 members split)
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "p8q9r0s1t2u3"
down_revision: Union[str, None] = "o7p8q9r0s1t2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "fantasy_leagues",
        sa.Column("parent_league_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_fantasy_leagues_parent",
        "fantasy_leagues",
        "fantasy_leagues",
        ["parent_league_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.add_column(
        "fantasy_leagues",
        sa.Column("auto_created", sa.Boolean(), server_default=sa.false(), nullable=False),
    )


def downgrade() -> None:
    op.drop_constraint("fk_fantasy_leagues_parent", "fantasy_leagues", type_="foreignkey")
    op.drop_column("fantasy_leagues", "auto_created")
    op.drop_column("fantasy_leagues", "parent_league_id")
