"""add_avatar_upload_ledgers

Revision ID: 4f8c6d7e1a2b
Revises: 9c6f3a1d2b4e
Create Date: 2026-06-10 11:35:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "4f8c6d7e1a2b"
down_revision: Union[str, Sequence[str], None] = "9c6f3a1d2b4e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "avatar_upload_ledgers",
        sa.Column("id", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("object_key", sa.String(length=500), nullable=False),
        sa.Column("avatar_url", sa.String(length=500), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("committed_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("object_key", name="uq_avatar_upload_ledger_object_key"),
    )


def downgrade() -> None:
    op.drop_table("avatar_upload_ledgers")
