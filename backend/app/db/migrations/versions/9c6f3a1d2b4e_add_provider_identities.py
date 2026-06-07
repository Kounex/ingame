"""add_provider_identities

Revision ID: 9c6f3a1d2b4e
Revises: 5ad1cb5db245, 8f4f2f09f2d1
Create Date: 2026-06-07 12:45:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "9c6f3a1d2b4e"
down_revision: Union[str, Sequence[str], None] = ("5ad1cb5db245", "8f4f2f09f2d1")
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "provider_identities",
        sa.Column("id", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("provider", sa.String(length=32), nullable=False),
        sa.Column("auth_mode", sa.String(length=32), nullable=False),
        sa.Column("external_id", sa.String(length=255), nullable=True),
        sa.Column("username", sa.String(length=255), nullable=True),
        sa.Column("display_name", sa.String(length=255), nullable=True),
        sa.Column("email", sa.String(length=255), nullable=True),
        sa.Column("avatar_url", sa.String(length=500), nullable=True),
        sa.Column("profile_url", sa.String(length=500), nullable=True),
        sa.Column("metadata", sa.JSON(), nullable=True),
        sa.Column("refresh_token", sa.String(length=1024), nullable=True),
        sa.Column("access_token_expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_synced_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "provider", name="uq_provider_identity_user_provider"),
    )

    op.execute(
        """
        insert into provider_identities (
            user_id,
            provider,
            auth_mode,
            external_id,
            display_name,
            avatar_url,
            last_synced_at
        )
        select
            id,
            'steam',
            'official_openid',
            steam_id,
            display_name,
            avatar_url,
            now()
        from users
        where steam_id is not null
        """
    )

    op.execute(
        """
        insert into provider_identities (
            user_id,
            provider,
            auth_mode,
            external_id,
            email
        )
        select
            id,
            'apple',
            'official_oauth',
            apple_id,
            email
        from users
        where apple_id is not null
        """
    )


def downgrade() -> None:
    op.drop_table("provider_identities")
