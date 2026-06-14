import uuid

from fastapi import WebSocket, WebSocketDisconnect

from app.auth.jwt import decode_token
from app.db.database import async_session_factory
from app.db.repositories.group_repo import GroupRepository
from app.db.repositories.user_repo import UserRepository
from app.redis.status_store import (
    clear_group_ready,
    clear_user_connection,
    set_group_ready,
    set_user_connection,
    CONNECTION_AWAY,
    CONNECTION_ONLINE,
)
from app.notifications.dispatcher import enqueue_notification
from app.ws.manager import manager


async def authenticate_ws(token: str) -> tuple[uuid.UUID, str, list[str]] | None:
    """Authenticate WebSocket connection. Returns (user_id, display_name, group_ids) or None."""
    try:
        payload = decode_token(token)
    except ValueError:
        return None

    if payload.get("type") != "access":
        return None

    user_id = payload["user_id"]

    async with async_session_factory() as session:
        user_repo = UserRepository(session)
        user = await user_repo.get_by_id(user_id)
        if user is None:
            return None

        group_repo = GroupRepository(session)
        groups = await group_repo.list_user_groups(user_id)
        group_ids = [str(g.id) for g in groups]

        return user_id, user.display_name, group_ids


async def handle_connect(websocket: WebSocket, token: str) -> uuid.UUID | None:
    result = await authenticate_ws(token)
    if result is None:
        await websocket.close(code=4001, reason="Authentication failed")
        return None

    user_id, display_name, group_ids = result
    await set_user_connection(str(user_id), CONNECTION_ONLINE)
    is_first_connection = await manager.connect(websocket, user_id, group_ids)
    await manager.sweep_all_groups(group_ids)
    await manager.send_presence_snapshot(user_id, group_ids, websocket)
    if is_first_connection:
        await manager.publish_user_online(user_id, display_name, group_ids)
    return user_id


async def handle_disconnect(user_id: uuid.UUID, websocket: WebSocket) -> None:
    group_ids = list(manager._user_groups.get(user_id, []))
    was_last_connection = await manager.disconnect(user_id, websocket)
    if was_last_connection:
        await clear_user_connection(str(user_id))
        await manager.publish_user_offline(user_id, group_ids)


async def _publish_ready_changed(
    user_id: uuid.UUID,
    group_id: str,
    *,
    ready: bool,
    ready_since: str | None = None,
    ready_expires_at: str | None = None,
) -> None:
    await manager.publish_ready_changed(
        user_id,
        group_id,
        ready=ready,
        ready_since=ready_since,
        ready_expires_at=ready_expires_at,
    )


async def handle_message(user_id: uuid.UUID, data: dict) -> None:
    """Route incoming WebSocket messages to appropriate handlers."""
    msg_type = data.get("type")
    group_ids = manager._user_groups.get(user_id, [])

    if msg_type == "presence_lifecycle":
        state = data.get("state")
        if state == "away":
            connection = CONNECTION_AWAY
        elif state == "active":
            connection = CONNECTION_ONLINE
        else:
            return

        await set_user_connection(str(user_id), connection)
        for group_id in group_ids:
            await manager.publish_connection_changed(user_id, group_id, connection)
        return

    if msg_type == "ready_toggle":
        group_id = data.get("group_id")
        ready = data.get("ready")
        if not isinstance(group_id, str) or group_id not in group_ids:
            return
        if not isinstance(ready, bool):
            return

        if ready:
            payload = await set_group_ready(group_id, str(user_id))
            await _publish_ready_changed(
                user_id,
                group_id,
                ready=True,
                ready_since=payload["since"],
                ready_expires_at=payload["expires_at"],
            )
            enqueue_notification(
                event_type="ready_changed",
                group_id=uuid.UUID(group_id),
                actor_user_id=user_id,
                payload={},
            )
        else:
            await clear_group_ready(group_id, str(user_id))
            await _publish_ready_changed(user_id, group_id, ready=False)
        return


async def websocket_endpoint(websocket: WebSocket, token: str | None = None):
    """Main WebSocket endpoint handler."""
    if not token:
        await websocket.close(code=4001, reason="Token required")
        return

    user_id = await handle_connect(websocket, token)
    if user_id is None:
        return

    try:
        while True:
            data = await websocket.receive_json()
            await handle_message(user_id, data)
    except WebSocketDisconnect:
        await handle_disconnect(user_id, websocket)
    except Exception:
        await handle_disconnect(user_id, websocket)
