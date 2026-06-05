import asyncio
import logging
import uuid

from fastapi import WebSocket

from app.redis.pubsub import publish_event, subscribe_to_patterns
from app.redis.status_store import (
    add_to_group_online,
    get_group_presence_snapshot,
    remove_from_group_online,
    sweep_expired_ready,
)
from app.ws.events import (
    ActivityRecordedEvent,
    EventType,
    GroupPresenceSnapshot,
    MemberPresence,
    PresenceSnapshotEvent,
    ScheduledReadyDeletedEvent,
    ScheduledReadyUpdatedEvent,
    SessionProposedEvent,
    SessionRsvpUpdatedEvent,
    SessionUpdatedEvent,
    UserOfflineEvent,
    UserOnlineEvent,
)

logger = logging.getLogger(__name__)
_PUBSUB_RETRY_DELAY_SECONDS = 1.0


class ConnectionManager:
    def __init__(self):
        self._connections: dict[uuid.UUID, set[WebSocket]] = {}
        self._user_groups: dict[uuid.UUID, list[str]] = {}
        self._sweep_task: asyncio.Task | None = None

    async def connect(
        self, websocket: WebSocket, user_id: uuid.UUID, group_ids: list[str]
    ) -> bool:
        """Connect a WebSocket for a user. Returns True for the first active connection."""
        await websocket.accept()
        existing = self._connections.get(user_id)
        is_first = existing is None or not existing
        if is_first:
            self._connections[user_id] = {websocket}
            self._user_groups[user_id] = group_ids
            for group_id in group_ids:
                await add_to_group_online(group_id, str(user_id))
        else:
            existing.add(websocket)
            self._user_groups[user_id] = group_ids
        return is_first

    async def send_presence_snapshot(
        self,
        user_id: uuid.UUID,
        group_ids: list[str],
        websocket: WebSocket,
    ) -> None:
        groups: list[GroupPresenceSnapshot] = []
        for group_id in group_ids:
            snapshot = await get_group_presence_snapshot(group_id)
            groups.append(
                GroupPresenceSnapshot(
                    group_id=uuid.UUID(snapshot["group_id"]),
                    members=[
                        MemberPresence(
                            user_id=uuid.UUID(member["user_id"]),
                            connection=member["connection"],
                            ready=member["ready"],
                            ready_since=member.get("ready_since"),
                            ready_expires_at=member.get("ready_expires_at"),
                        )
                        for member in snapshot["members"]
                    ],
                )
            )

        event = PresenceSnapshotEvent(groups=groups)
        await websocket.send_json(event.model_dump(mode="json"))

    async def publish_user_online(
        self, user_id: uuid.UUID, display_name: str, group_ids: list[str]
    ) -> None:
        for group_id in group_ids:
            event = UserOnlineEvent(
                user_id=user_id,
                display_name=display_name,
                group_id=uuid.UUID(group_id),
            )
            await publish_event(f"group:{group_id}:events", event.model_dump(mode="json"))

    async def disconnect(self, user_id: uuid.UUID, websocket: WebSocket) -> bool:
        """Disconnect one WebSocket. Returns True when the user has no active connections."""
        connections = self._connections.get(user_id)
        if connections is None:
            return True

        connections.discard(websocket)
        if connections:
            return False

        group_ids = self._user_groups.pop(user_id, [])
        self._connections.pop(user_id, None)

        for group_id in group_ids:
            await remove_from_group_online(group_id, str(user_id))
        return True

    async def publish_user_offline(self, user_id: uuid.UUID, group_ids: list[str]) -> None:
        for group_id in group_ids:
            event = UserOfflineEvent(user_id=user_id, group_id=uuid.UUID(group_id))
            await publish_event(f"group:{group_id}:events", event.model_dump(mode="json"))

    async def publish_ready_changed(
        self,
        user_id: uuid.UUID,
        group_id: str,
        *,
        ready: bool,
        ready_since: str | None = None,
        ready_expires_at: str | None = None,
    ) -> None:
        from app.ws.events import ReadyChangedEvent

        event = ReadyChangedEvent(
            user_id=user_id,
            group_id=uuid.UUID(group_id),
            ready=ready,
            ready_since=ready_since,
            ready_expires_at=ready_expires_at,
        )
        await publish_event(f"group:{group_id}:events", event.model_dump(mode="json"))

    async def publish_connection_changed(
        self,
        user_id: uuid.UUID,
        group_id: str,
        connection: str,
    ) -> None:
        from app.ws.events import ConnectionChangedEvent

        event = ConnectionChangedEvent(
            user_id=user_id,
            group_id=uuid.UUID(group_id),
            connection=connection,
        )
        await publish_event(f"group:{group_id}:events", event.model_dump(mode="json"))

    async def publish_scheduled_ready_updated(self, window: dict) -> None:
        group_id = window["group_id"]
        event = ScheduledReadyUpdatedEvent(group_id=uuid.UUID(group_id), window=window)
        await publish_event(f"group:{group_id}:events", event.model_dump(mode="json"))

    async def publish_scheduled_ready_deleted(self, payload: dict) -> None:
        group_id = payload["group_id"]
        event = ScheduledReadyDeletedEvent(
            group_id=uuid.UUID(group_id),
            window_id=uuid.UUID(payload["window_id"]),
            user_id=uuid.UUID(payload["user_id"]),
        )
        await publish_event(f"group:{group_id}:events", event.model_dump(mode="json"))

    async def publish_session_proposed(self, session: dict) -> None:
        group_id = session["group_id"]
        event = SessionProposedEvent(group_id=uuid.UUID(group_id), session=session)
        await publish_event(f"group:{group_id}:events", event.model_dump(mode="json"))

    async def publish_session_updated(self, session: dict) -> None:
        group_id = session["group_id"]
        event = SessionUpdatedEvent(group_id=uuid.UUID(group_id), session=session)
        await publish_event(f"group:{group_id}:events", event.model_dump(mode="json"))

    async def publish_session_rsvp_updated(self, group_id: str, rsvp: dict) -> None:
        event = SessionRsvpUpdatedEvent(group_id=uuid.UUID(group_id), rsvp=rsvp)
        await publish_event(f"group:{group_id}:events", event.model_dump(mode="json"))

    async def publish_activity_recorded(self, activity: dict) -> None:
        group_id = activity["group_id"]
        event = ActivityRecordedEvent(group_id=uuid.UUID(group_id), activity=activity)
        await publish_event(f"group:{group_id}:events", event.model_dump(mode="json"))

    async def sweep_all_groups(self, group_ids: list[str]) -> None:
        for group_id in group_ids:
            expired_user_ids = await sweep_expired_ready(group_id)
            for expired_user_id in expired_user_ids:
                await self.publish_ready_changed(
                    uuid.UUID(expired_user_id),
                    group_id,
                    ready=False,
                )

    async def broadcast_event(self, event: dict) -> None:
        group_id = event.get("group_id")
        if group_id is None or event.get("type") == EventType.PRESENCE_SNAPSHOT.value:
            return

        exclude = None
        if event.get("type") in {
            EventType.USER_ONLINE.value,
            EventType.USER_OFFLINE.value,
            EventType.CONNECTION_CHANGED.value,
            EventType.READY_CHANGED.value,
        }:
            user_id = event.get("user_id")
            if user_id is not None:
                exclude = uuid.UUID(user_id)

        await self.broadcast_to_group(
            str(group_id),
            event,
            exclude=exclude,
        )

    async def run_pubsub_listener(self) -> None:
        self._sweep_task = asyncio.create_task(self._run_ready_sweep_loop())
        try:
            while True:
                try:
                    async for event in subscribe_to_patterns(["group:*:events"]):
                        await self.broadcast_event(event)
                except asyncio.CancelledError:
                    raise
                except Exception:
                    logger.exception("Pub/sub listener failed; retrying")
                    await asyncio.sleep(_PUBSUB_RETRY_DELAY_SECONDS)
        finally:
            if self._sweep_task is not None:
                self._sweep_task.cancel()
                try:
                    await self._sweep_task
                except asyncio.CancelledError:
                    pass

    async def _run_ready_sweep_loop(self) -> None:
        while True:
            await asyncio.sleep(60)
            group_ids = {
                group_id
                for group_ids in self._user_groups.values()
                for group_id in group_ids
            }
            if group_ids:
                await self.sweep_all_groups(sorted(group_ids))

    async def send_to_user(self, user_id: uuid.UUID, event: dict) -> None:
        for ws in list(self._connections.get(user_id, ())):
            try:
                await ws.send_json(event)
            except Exception:
                pass

    async def broadcast_to_group(
        self, group_id: str, event: dict, exclude: uuid.UUID | None = None
    ) -> None:
        for uid, websockets in self._connections.items():
            if uid == exclude:
                continue
            user_groups = self._user_groups.get(uid, [])
            if group_id not in user_groups:
                continue
            for ws in websockets:
                try:
                    await ws.send_json(event)
                except Exception:
                    pass


manager = ConnectionManager()
