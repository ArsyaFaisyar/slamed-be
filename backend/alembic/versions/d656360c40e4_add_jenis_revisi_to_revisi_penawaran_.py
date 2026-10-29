"""add jenis revisi to revisi penawaran items

Revision ID: d656360c40e4
Revises: 05fd06d1c4d5
Create Date: 2026-10-29 15:53:21.629599

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd656360c40e4'
down_revision: Union[str, Sequence[str], None] = '05fd06d1c4d5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None



def upgrade() -> None:
    op.create_table(
        "revisi_penawaran_items",
        sa.Column("id", sa.Integer(), primary_key=True, nullable=False),
        sa.Column(
            "revisi_penawaran_id",
            sa.Integer(),
            sa.ForeignKey("revisi_penawaran.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("nama_barang", sa.String(length=150), nullable=False),
        sa.Column("merk", sa.String(length=150), nullable=True),
        sa.Column("tkdn", sa.String(length=30), nullable=True),
        sa.Column("tkdn_persen", sa.Numeric(5, 2), nullable=True),
        sa.Column("spesifikasi", sa.Text(), nullable=True),
        sa.Column("catatan_sales", sa.Text(), nullable=True),
        sa.Column("jumlah", sa.Numeric(12, 2), nullable=False),
        sa.Column("satuan", sa.String(length=50), nullable=False),
        sa.Column("gambar_path", sa.String(), nullable=True),
        sa.Column("link_marketplace", sa.String(), nullable=True),
        sa.Column(
            "jenis_pajak",
            sa.String(length=20),
            server_default="PAJAK",
            nullable=False,
        ),
        sa.Column("harga_pagu", sa.Numeric(15, 2), nullable=True),
        sa.Column("harga_modal", sa.Numeric(15, 2), nullable=True),
        sa.Column("harga_jual", sa.Numeric(15, 2), nullable=True),
        sa.Column(
            "jenis_revisi",
            sa.String(length=30),
            server_default="REVISI_HARGA_BARANG",
            nullable=False,
        ),
    )

    op.create_index(
        "ix_revisi_penawaran_items_id",
        "revisi_penawaran_items",
        ["id"],
        unique=False,
    )
    op.create_index(
        "ix_revisi_penawaran_items_revisi_penawaran_id",
        "revisi_penawaran_items",
        ["revisi_penawaran_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_revisi_penawaran_items_revisi_penawaran_id",
        table_name="revisi_penawaran_items",
    )
    op.drop_index(
        "ix_revisi_penawaran_items_id",
        table_name="revisi_penawaran_items",
    )
    op.drop_table("revisi_penawaran_items")

