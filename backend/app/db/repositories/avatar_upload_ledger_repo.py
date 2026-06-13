import uuid
from datetime import datetime, timezone

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.avatar_upload_ledger import AvatarUploadLedger


def _as_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


class AvatarUploadLedgerRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create_pending(
        self,
        *,
        user_id: uuid.UUID,
        object_key: str,
        avatar_url: str,
    ) -> AvatarUploadLedger:
        record = AvatarUploadLedger(
            user_id=user_id,
            object_key=object_key,
            avatar_url=avatar_url,
        )
        self.session.add(record)
        await self.session.flush()
        await self.session.refresh(record)
        return record

    async def get_by_id(self, ledger_id: uuid.UUID) -> AvatarUploadLedger | None:
        result = await self.session.execute(
            select(AvatarUploadLedger)
            .where(AvatarUploadLedger.id == ledger_id)
            .execution_options(populate_existing=True)
        )
        return result.scalar_one_or_none()

    async def get_by_avatar_url(self, avatar_url: str) -> AvatarUploadLedger | None:
        result = await self.session.execute(
            select(AvatarUploadLedger)
            .where(AvatarUploadLedger.avatar_url == avatar_url)
            .execution_options(populate_existing=True)
        )
        return result.scalar_one_or_none()

    async def mark_committed(
        self,
        *,
        user_id: uuid.UUID,
        avatar_url: str,
    ) -> AvatarUploadLedger | None:
        result = await self.session.execute(
            select(AvatarUploadLedger).where(
                AvatarUploadLedger.user_id == user_id,
                AvatarUploadLedger.avatar_url == avatar_url,
            )
            .execution_options(populate_existing=True)
        )
        record = result.scalar_one_or_none()
        if record is None:
            return None

        if record.committed_at is None:
            record.committed_at = datetime.now(timezone.utc)
            await self.session.flush()
            await self.session.refresh(record)
        return record

    async def list_expired_pending(
        self,
        *,
        created_before: datetime,
    ) -> list[AvatarUploadLedger]:
        result = await self.session.execute(
            select(AvatarUploadLedger)
            .where(AvatarUploadLedger.committed_at.is_(None))
            .order_by(AvatarUploadLedger.created_at.asc())
            .execution_options(populate_existing=True)
        )
        cutoff = _as_utc(created_before)
        return [
            record
            for record in result.scalars()
            if _as_utc(record.created_at) < cutoff
        ]

    async def delete(self, ledger_id: uuid.UUID) -> None:
        await self.session.execute(
            delete(AvatarUploadLedger).where(AvatarUploadLedger.id == ledger_id)
        )
        await self.session.flush()
