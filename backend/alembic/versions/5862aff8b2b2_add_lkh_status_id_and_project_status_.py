"""add lkh status id and project status history

Revision ID: 5862aff8b2b2
Revises: 6d6800ba991f
Create Date: 2026-10-20 14:33:10.920643

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '5862aff8b2b2'
down_revision = "6d6800ba991f"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "lkh",
        sa.Column("status_id", sa.Integer(), nullable=True),
    )

    op.create_foreign_key(
        "fk_lkh_status_id_project_statuses",
        "lkh",
        "project_statuses",
        ["status_id"],
        ["id"],
    )

    op.create_table(
        "project_status_histories",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("project_id", sa.Integer(), nullable=False),
        sa.Column("old_status_id", sa.Integer(), nullable=True),
        sa.Column("new_status_id", sa.Integer(), nullable=False),
        sa.Column("changed_by", sa.Integer(), nullable=False),
        sa.Column("source_lkh_id", sa.Integer(), nullable=True),
        sa.Column("catatan", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["project_id"],
            ["project_prospek.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["old_status_id"],
            ["project_statuses.id"],
        ),
        sa.ForeignKeyConstraint(
            ["new_status_id"],
            ["project_statuses.id"],
        ),
        sa.ForeignKeyConstraint(
            ["changed_by"],
            ["users.id"],
        ),
        sa.ForeignKeyConstraint(
            ["source_lkh_id"],
            ["lkh.id"],
            ondelete="SET NULL",
        ),
    )

    op.create_index(
        "ix_project_status_histories_project_id",
        "project_status_histories",
        ["project_id"],
    )


def downgrade():
    op.drop_index(
        "ix_project_status_histories_project_id",
        table_name="project_status_histories",
    )
    op.drop_table("project_status_histories")

    op.drop_constraint(
        "fk_lkh_status_id_project_statuses",
        "lkh",
        type_="foreignkey",
    )
    op.drop_column("lkh", "status_id")
