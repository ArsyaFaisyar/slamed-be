"""add is_tambahan to request_penawaran_items

Revision ID: 80663441d0da
Revises: e5f3944065c0
Create Date: 2026-10-29 13:12:17.060052

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '80663441d0da'
down_revision: Union[str, Sequence[str], None] = 'e5f3944065c0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE request_penawaran_items "
        "ADD COLUMN IF NOT EXISTS is_tambahan BOOLEAN NOT NULL DEFAULT FALSE"
    )


def downgrade() -> None:
    op.execute(
        "ALTER TABLE request_penawaran_items "
        "DROP COLUMN IF EXISTS is_tambahan"
    )