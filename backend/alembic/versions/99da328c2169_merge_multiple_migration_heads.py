"""merge multiple migration heads

Revision ID: 99da328c2169
Revises: 56918f78f144, 6dbb8aa1c6de, 80663441d0da
Create Date: 2026-10-29 15:47:59.176949

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '99da328c2169'
down_revision: Union[str, Sequence[str], None] = ('56918f78f144', '6dbb8aa1c6de', '80663441d0da')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
