"""merge project and lkh status migrations

Revision ID: 2fa4730aad3b
Revises: 1586daf7da5d, 5862aff8b2b2
Create Date: 2026-10-20 15:21:31.948220

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '2fa4730aad3b'
down_revision: Union[str, Sequence[str], None] = ('1586daf7da5d', '5862aff8b2b2')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
