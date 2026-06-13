import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.notification_preference import NotificationPreference

_DEFAULT_PREFERENCES = [
    {"event_type": "ready_changed", "enabled": True, "conditions": None},
    {"event_type": "session_proposed", "enabled": True, "conditions": None},
    {"event_type": "session_updated", "enabled": True, "conditions": {"only_if_rsvp": ["in", "maybe"]}},
    {"event_type": "session_rsvp_updated", "enabled": True, "conditions": None},
    {"event_type": "join_request_pending", "enabled": True, "conditions": {"only_if_role": ["owner", "admin"]}},
]


class NotificationPreferenceRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def has_preferences(self, user_id: uuid.UUID) -> bool:
        result = await self.session.execute(
            select(NotificationPreference.id).where(
                NotificationPreference.user_id == user_id,
            ).limit(1)
        )
        return result.scalar_one_or_none() is not None

    async def seed_defaults(self, user_id: uuid.UUID) -> None:
        if await self.has_preferences(user_id):
            return
        for default in _DEFAULT_PREFERENCES:
            pref = NotificationPreference(
                user_id=user_id,
                scope="global",
                scope_id=None,
                event_type=default["event_type"],
                enabled=default["enabled"],
                conditions=default["conditions"],
            )
            self.session.add(pref)
        await self.session.flush()

    async def list_for_user(self, user_id: uuid.UUID) -> list[NotificationPreference]:
        result = await self.session.execute(
            select(NotificationPreference).where(
                NotificationPreference.user_id == user_id,
            )
        )
        return list(result.scalars().all())

    async def get_for_user_event(
        self, user_id: uuid.UUID, event_type: str
    ) -> NotificationPreference | None:
        result = await self.session.execute(
            select(NotificationPreference).where(
                NotificationPreference.user_id == user_id,
                NotificationPreference.scope == "global",
                NotificationPreference.event_type == event_type,
            )
        )
        return result.scalar_one_or_none()

    async def get_group_preference(
        self, user_id: uuid.UUID, group_id: uuid.UUID
    ) -> NotificationPreference | None:
        result = await self.session.execute(
            select(NotificationPreference).where(
                NotificationPreference.user_id == user_id,
                NotificationPreference.scope == "group",
                NotificationPreference.scope_id == group_id,
                NotificationPreference.event_type.is_(None),
            )
        )
        return result.scalar_one_or_none()

    async def list_for_group(
        self, user_id: uuid.UUID, group_id: uuid.UUID
    ) -> list[NotificationPreference]:
        result = await self.session.execute(
            select(NotificationPreference).where(
                NotificationPreference.user_id == user_id,
                NotificationPreference.scope == "group",
                NotificationPreference.scope_id == group_id,
            )
        )
        return list(result.scalars().all())
