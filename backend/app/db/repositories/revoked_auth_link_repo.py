import uuid

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.revoked_auth_link import RevokedAuthLink


class RevokedAuthLinkRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get(self, provider: str, external_id: str) -> RevokedAuthLink | None:
        result = await self.session.execute(
            select(RevokedAuthLink).where(
                RevokedAuthLink.provider == provider,
                RevokedAuthLink.external_id == external_id,
            )
        )
        return result.scalar_one_or_none()

    async def upsert(
        self, *, user_id: uuid.UUID, provider: str, external_id: str
    ) -> RevokedAuthLink:
        record = await self.get(provider, external_id)
        if record is None:
            record = RevokedAuthLink(
                user_id=user_id,
                provider=provider,
                external_id=external_id,
            )
            self.session.add(record)
        else:
            record.user_id = user_id
            record.external_id = external_id
        await self.session.flush()
        await self.session.refresh(record)
        return record

    async def delete(self, provider: str, external_id: str) -> None:
        await self.session.execute(
            delete(RevokedAuthLink).where(
                RevokedAuthLink.provider == provider,
                RevokedAuthLink.external_id == external_id,
            )
        )
        await self.session.flush()
