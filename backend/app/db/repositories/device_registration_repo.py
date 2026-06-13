import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.device_registration import DeviceRegistration


class DeviceRegistrationRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_by_id(self, registration_id: uuid.UUID) -> DeviceRegistration | None:
        result = await self.session.execute(
            select(DeviceRegistration).where(DeviceRegistration.id == registration_id)
        )
        return result.scalar_one_or_none()

    async def upsert(
        self,
        *,
        user_id: uuid.UUID,
        platform: str,
        token: str,
        device_label: str | None = None,
        app_version: str | None = None,
    ) -> DeviceRegistration:
        result = await self.session.execute(
            select(DeviceRegistration).where(
                DeviceRegistration.user_id == user_id,
                DeviceRegistration.token == token,
            )
        )
        existing = result.scalar_one_or_none()

        if existing is not None:
            existing.platform = platform
            existing.last_seen_at = datetime.now(timezone.utc)
            existing.revoked_at = None
            if device_label is not None:
                existing.device_label = device_label
            if app_version is not None:
                existing.app_version = app_version
            await self.session.flush()
            await self.session.refresh(existing)
            return existing

        registration = DeviceRegistration(
            user_id=user_id,
            platform=platform,
            token=token,
            device_label=device_label,
            app_version=app_version,
        )
        self.session.add(registration)
        await self.session.flush()
        await self.session.refresh(registration)
        return registration

    async def list_active_for_user(self, user_id: uuid.UUID) -> list[DeviceRegistration]:
        result = await self.session.execute(
            select(DeviceRegistration).where(
                DeviceRegistration.user_id == user_id,
                DeviceRegistration.revoked_at.is_(None),
            )
        )
        return list(result.scalars().all())

    async def list_all_for_user(self, user_id: uuid.UUID) -> list[DeviceRegistration]:
        result = await self.session.execute(
            select(DeviceRegistration).where(DeviceRegistration.user_id == user_id)
        )
        return list(result.scalars().all())

    async def revoke(self, registration_id: uuid.UUID) -> bool:
        reg = await self.get_by_id(registration_id)
        if reg is None:
            return False
        reg.revoked_at = datetime.now(timezone.utc)
        await self.session.flush()
        return True

    async def revoke_by_token(self, user_id: uuid.UUID, token: str) -> bool:
        result = await self.session.execute(
            select(DeviceRegistration).where(
                DeviceRegistration.user_id == user_id,
                DeviceRegistration.token == token,
                DeviceRegistration.revoked_at.is_(None),
            )
        )
        reg = result.scalar_one_or_none()
        if reg is None:
            return False
        reg.revoked_at = datetime.now(timezone.utc)
        await self.session.flush()
        return True

    async def delete(self, registration_id: uuid.UUID) -> bool:
        reg = await self.get_by_id(registration_id)
        if reg is None:
            return False
        await self.session.delete(reg)
        await self.session.flush()
        return True

    async def list_stale(self, cutoff: datetime) -> list[DeviceRegistration]:
        result = await self.session.execute(
            select(DeviceRegistration).where(
                DeviceRegistration.last_seen_at < cutoff,
                DeviceRegistration.revoked_at.is_(None),
            )
        )
        return list(result.scalars().all())
