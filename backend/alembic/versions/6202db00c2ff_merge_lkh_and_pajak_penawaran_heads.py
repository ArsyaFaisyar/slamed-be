"""merge lkh and pajak penawaran heads

Revision ID: 6202db00c2ff
Revises: 63d855944094, e5f3944065c0
Create Date: 2026-10-29 11:11:04.370521

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '6202db00c2ff'
down_revision: Union[str, Sequence[str], None] = ('63d855944094', 'e5f3944065c0')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
