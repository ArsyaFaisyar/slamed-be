"""add status id to project prospek

Revision ID: 1586daf7da5d
Revises: 5862aff8b2b2
Create Date: 2026-10-20 15:19:16.980822

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '1586daf7da5d'
down_revision = "6d6800ba991f"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "project_prospek",
        sa.Column("status_id", sa.Integer(), nullable=True),
    )

    op.create_foreign_key(
        "fk_project_prospek_status_id",
        "project_prospek",
        "project_statuses",
        ["status_id"],
        ["id"],
    )


def downgrade():
    op.drop_constraint(
        "fk_project_prospek_status_id",
        "project_prospek",
        type_="foreignkey",
    )
    op.drop_column("project_prospek", "status_id")
