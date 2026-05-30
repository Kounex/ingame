import asyncio
import uuid

from fastapi import WebSocket

from app.redis.pubsub import publish_event, subscribe_to_patterns
from app.redis.status_store import add_to_group_online, get_group_presence_snapshot, remove_from_group_online
from app.ws.events import EventType, GroupPresenceSnapshot, PresenceSnapshotEvent, UserOfflineEvent, UserOnlineEvent, UserPresence


class ConnectionManager:
    def __init__(self):
        self._connections: dict[uuid.UUID, WebSocket] = {}
        self._user_groups: dict[uuid.UUID, list[str]] = {}

    async def connect(
        self, websocket: WebSocket, user_id: uuid.UUID, group_ids: list[str]
    ) -> None:
        await websocket.accept()
        self._connections[user_id] = websocket
        self._user_groups[user_id] = group_ids

        for group_id in group_ids:
            await add_to_group_online(group_id, str(user_id))

    async def send_presence_snapshot(
        self, user_id: uuid.UUID, group_ids: list[str]
    ) -> None:
        groups: list[GroupPresenceSnapshot] = []
        for group_id in group_ids:
            snapshot = await get_group_presence_snapshot(group_id)
            groups.append(
                GroupPresenceSnapshot(
                    group_id=uuid.UUID(snapshot["group_id"]),
                    online_user_ids=[
                        uuid.UUID(member_id) for member_id in snapshot["online_user_ids"]
                    ],
                    statuses=[
                        UserPresence(
                            user_id=uuid.UUID(status["user_id"]),
                            state=status["state"],
                            game=status.get("game"),
                            since=status.get("since"),
                        )
                        for status in snapshot["statuses"]
                    ],
                )
            )

        event = PresenceSnapshotEvent(groups=groups)
        await self.send_to_user(user_id, event.model_dump(mode="json"))

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

    async def disconnect(self, user_id: uuid.UUID) -> None:
        group_ids = self._user_groups.pop(user_id, [])
        self._connections.pop(user_id, None)

        for group_id in group_ids:
            await remove_from_group_online(group_id, str(user_id))

    async def publish_user_offline(self, user_id: uuid.UUID, group_ids: list[str]) -> None:
        for group_id in group_ids:
            event = UserOfflineEvent(user_id=user_id, group_id=uuid.UUID(group_id))
            await publish_event(f"group:{group_id}:events", event.model_dump(mode="json"))

    async def broadcast_event(self, event: dict) -> None:
        group_id = event.get("group_id")
        if group_id is None or event.get("type") == EventType.PRESENCE_SNAPSHOT.value:
            return

        exclude = None
        if event.get("type") in {
            EventType.USER_ONLINE.value,
            EventType.USER_OFFLINE.value,
            EventType.STATUS_CHANGED.value,
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
        try:
            async for event in subscribe_to_patterns(["group:*:events"]):
                await self.broadcast_event(event)
        except asyncio.CancelledError:
            raise
        except Exception:
            # Keep the process alive; tests cover delivery semantics.
            return

    async def send_to_user(self, user_id: uuid.UUID, event: dict) -> None:
        ws = self._connections.get(user_id)
        if ws:
            await ws.send_json(event)

    async def broadcast_to_group(
        self, group_id: str, event: dict, exclude: uuid.UUID | None = None
    ) -> None:
        for uid, ws in self._connections.items():
            if uid == exclude:
                continue
            user_groups = self._user_groups.get(uid, [])
            if group_id in user_groups:
                try:
                    await ws.send_json(event)
                except Exception:
                    pass


manager = ConnectionManager()
