import uuid

from fastapi import WebSocket, WebSocketDisconnect

from app.auth.jwt import decode_token
from app.db.database import async_session_factory
from app.db.repositories.group_repo import GroupRepository
from app.db.repositories.user_repo import UserRepository
from app.redis.pubsub import publish_event
from app.redis.status_store import set_user_status, clear_user_status
from app.ws.events import StatusChangedEvent
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
    await set_user_status(str(user_id), "online")
    await manager.connect(websocket, user_id, group_ids)
    await manager.send_presence_snapshot(user_id, group_ids)
    await manager.publish_user_online(user_id, display_name, group_ids)
    return user_id


async def handle_disconnect(user_id: uuid.UUID) -> None:
    group_ids = list(manager._user_groups.get(user_id, []))
    await manager.disconnect(user_id)
    await clear_user_status(str(user_id))
    await manager.publish_user_offline(user_id, group_ids)


async def handle_message(user_id: uuid.UUID, data: dict) -> None:
    """Route incoming WebSocket messages to appropriate handlers."""
    msg_type = data.get("type")

    if msg_type == "status_change":
        valid_states = {"online", "ready", "away", "offline"}
        state = data.get("state", "online")
        if state not in valid_states:
            return
        game = data.get("game")
        if game is not None and not isinstance(game, str):
            return
        await set_user_status(str(user_id), state, game)

        group_ids = manager._user_groups.get(user_id, [])
        for group_id in group_ids:
            event = StatusChangedEvent(
                user_id=user_id,
                state=state,
                game=game,
                group_id=uuid.UUID(group_id),
            )
            await publish_event(f"group:{group_id}:events", event.model_dump(mode="json"))


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
        await handle_disconnect(user_id)
    except Exception:
        await handle_disconnect(user_id)
