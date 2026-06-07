import uuid
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.provider_identity import ProviderIdentity


class ProviderIdentityRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def list_for_user(self, user_id: uuid.UUID) -> list[ProviderIdentity]:
        result = await self.session.execute(
            select(ProviderIdentity)
            .where(ProviderIdentity.user_id == user_id)
            .order_by(ProviderIdentity.provider.asc())
        )
        return list(result.scalars().all())

    async def get_for_user(
        self, user_id: uuid.UUID, provider: str
    ) -> ProviderIdentity | None:
        result = await self.session.execute(
            select(ProviderIdentity).where(
                ProviderIdentity.user_id == user_id,
                ProviderIdentity.provider == provider,
            )
        )
        return result.scalar_one_or_none()

    async def get_by_provider_external_id(
        self, provider: str, external_id: str
    ) -> ProviderIdentity | None:
        result = await self.session.execute(
            select(ProviderIdentity).where(
                ProviderIdentity.provider == provider,
                ProviderIdentity.external_id == external_id,
            )
        )
        return result.scalar_one_or_none()

    async def upsert(
        self,
        *,
        user_id: uuid.UUID,
        provider: str,
        auth_mode: str,
        external_id: str | None = None,
        username: str | None = None,
        display_name: str | None = None,
        email: str | None = None,
        avatar_url: str | None = None,
        profile_url: str | None = None,
        metadata: dict | None = None,
        refresh_token: str | None = None,
        access_token_expires_at: datetime | None = None,
        last_synced_at: datetime | None = None,
    ) -> ProviderIdentity:
        identity = await self.get_for_user(user_id, provider)
        if identity is None:
            identity = ProviderIdentity(
                user_id=user_id,
                provider=provider,
                auth_mode=auth_mode,
            )
            self.session.add(identity)

        identity.auth_mode = auth_mode
        identity.external_id = external_id
        identity.username = username
        identity.display_name = display_name
        identity.email = email
        identity.avatar_url = avatar_url
        identity.profile_url = profile_url
        identity.metadata_json = metadata
        identity.refresh_token = refresh_token
        identity.access_token_expires_at = access_token_expires_at
        identity.last_synced_at = last_synced_at

        await self.session.flush()
        await self.session.refresh(identity)
        return identity

    async def delete_for_user(self, user_id: uuid.UUID, provider: str) -> None:
        identity = await self.get_for_user(user_id, provider)
        if identity is None:
            return
        await self.session.delete(identity)
        await self.session.flush()
