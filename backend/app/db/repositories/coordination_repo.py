import uuid

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.coordination import (
    GroupActivityEvent,
    ScheduledReadyWindow,
    Session,
    SessionRsvp,
)


class CoordinationRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def list_scheduled_ready_windows(
        self, group_id: uuid.UUID
    ) -> list[ScheduledReadyWindow]:
        result = await self.session.execute(
            select(ScheduledReadyWindow)
            .where(ScheduledReadyWindow.group_id == group_id)
            .order_by(ScheduledReadyWindow.starts_at.asc(), ScheduledReadyWindow.created_at.asc())
        )
        return list(result.scalars().all())

    async def create_scheduled_ready_window(self, **kwargs) -> ScheduledReadyWindow:
        window = ScheduledReadyWindow(**kwargs)
        self.session.add(window)
        await self.session.flush()
        await self.session.refresh(window)
        return window

    async def get_scheduled_ready_window(
        self, window_id: uuid.UUID
    ) -> ScheduledReadyWindow | None:
        result = await self.session.execute(
            select(ScheduledReadyWindow).where(ScheduledReadyWindow.id == window_id)
        )
        return result.scalar_one_or_none()

    async def update_scheduled_ready_window(
        self, window_id: uuid.UUID, **kwargs
    ) -> ScheduledReadyWindow | None:
        window = await self.get_scheduled_ready_window(window_id)
        if window is None:
            return None
        for key, value in kwargs.items():
            if value is not None:
                setattr(window, key, value)
        await self.session.flush()
        await self.session.refresh(window)
        return window

    async def delete_scheduled_ready_window(self, window_id: uuid.UUID) -> bool:
        window = await self.get_scheduled_ready_window(window_id)
        if window is None:
            return False
        await self.session.delete(window)
        await self.session.flush()
        return True

    async def list_sessions(self, group_id: uuid.UUID) -> list[Session]:
        result = await self.session.execute(
            select(Session)
            .where(Session.group_id == group_id)
            .order_by(Session.starts_at.asc(), Session.created_at.asc())
        )
        return list(result.scalars().all())

    async def create_session(self, **kwargs) -> Session:
        session = Session(**kwargs)
        self.session.add(session)
        await self.session.flush()
        await self.session.refresh(session)
        return session

    async def get_session(self, session_id: uuid.UUID) -> Session | None:
        result = await self.session.execute(select(Session).where(Session.id == session_id))
        return result.scalar_one_or_none()

    async def update_session(self, session_id: uuid.UUID, **kwargs) -> Session | None:
        session = await self.get_session(session_id)
        if session is None:
            return None
        for key, value in kwargs.items():
            if value is not None:
                setattr(session, key, value)
        await self.session.flush()
        await self.session.refresh(session)
        return session

    async def list_rsvps_for_session(self, session_id: uuid.UUID) -> list[SessionRsvp]:
        result = await self.session.execute(
            select(SessionRsvp)
            .where(SessionRsvp.session_id == session_id)
            .order_by(SessionRsvp.updated_at.asc())
        )
        return list(result.scalars().all())

    async def list_rsvps_for_sessions(
        self, session_ids: list[uuid.UUID]
    ) -> list[SessionRsvp]:
        if not session_ids:
            return []
        result = await self.session.execute(
            select(SessionRsvp)
            .where(SessionRsvp.session_id.in_(session_ids))
            .order_by(SessionRsvp.updated_at.asc())
        )
        return list(result.scalars().all())

    async def get_rsvp(
        self, session_id: uuid.UUID, user_id: uuid.UUID
    ) -> SessionRsvp | None:
        result = await self.session.execute(
            select(SessionRsvp).where(
                SessionRsvp.session_id == session_id,
                SessionRsvp.user_id == user_id,
            )
        )
        return result.scalar_one_or_none()

    async def upsert_rsvp(
        self, session_id: uuid.UUID, user_id: uuid.UUID, response: str
    ) -> SessionRsvp:
        rsvp = await self.get_rsvp(session_id, user_id)
        if rsvp is None:
            rsvp = SessionRsvp(session_id=session_id, user_id=user_id, response=response)
            self.session.add(rsvp)
        else:
            rsvp.response = response
        await self.session.flush()
        await self.session.refresh(rsvp)
        return rsvp

    async def create_activity_event(self, **kwargs) -> GroupActivityEvent:
        event = GroupActivityEvent(**kwargs)
        self.session.add(event)
        await self.session.flush()
        await self.session.refresh(event)
        return event

    async def list_activity_events(
        self, group_id: uuid.UUID, *, limit: int = 50
    ) -> list[GroupActivityEvent]:
        result = await self.session.execute(
            select(GroupActivityEvent)
            .where(GroupActivityEvent.group_id == group_id)
            .order_by(GroupActivityEvent.created_at.desc())
            .limit(limit)
        )
        return list(result.scalars().all())

    async def clear_group_activity(self, group_id: uuid.UUID) -> None:
        await self.session.execute(
            delete(GroupActivityEvent).where(GroupActivityEvent.group_id == group_id)
        )
        await self.session.flush()
