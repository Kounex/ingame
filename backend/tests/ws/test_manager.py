import asyncio
import uuid
from unittest.mock import AsyncMock, call, patch

import pytest
from starlette.websockets import WebSocket

from app.ws.manager import ConnectionManager


@pytest.mark.asyncio
async def test_disconnect_one_of_two_connections_keeps_user_online():
    manager = ConnectionManager()
    user_id = uuid.uuid4()
    group_ids = ["group-1"]
    ws_a = AsyncMock(spec=WebSocket)
    ws_b = AsyncMock(spec=WebSocket)

    with patch("app.ws.manager.add_to_group_online", new_callable=AsyncMock) as add_online:
        with patch(
            "app.ws.manager.remove_from_group_online", new_callable=AsyncMock
        ) as remove_online:
            is_first_a = await manager.connect(ws_a, user_id, group_ids)
            is_first_b = await manager.connect(ws_b, user_id, group_ids)

            assert is_first_a is True
            assert is_first_b is False
            add_online.assert_awaited_once_with("group-1", str(user_id))

            was_last = await manager.disconnect(user_id, ws_a)

            assert was_last is False
            remove_online.assert_not_awaited()
            assert user_id in manager._connections
            assert ws_b in manager._connections[user_id]


@pytest.mark.asyncio
async def test_disconnect_last_connection_marks_user_offline():
    manager = ConnectionManager()
    user_id = uuid.uuid4()
    group_ids = ["group-1"]
    ws = AsyncMock(spec=WebSocket)

    with patch("app.ws.manager.add_to_group_online", new_callable=AsyncMock):
        with patch(
            "app.ws.manager.remove_from_group_online", new_callable=AsyncMock
        ) as remove_online:
            await manager.connect(ws, user_id, group_ids)
            was_last = await manager.disconnect(user_id, ws)

            assert was_last is True
            remove_online.assert_awaited_once_with("group-1", str(user_id))
            assert user_id not in manager._connections


@pytest.mark.asyncio
async def test_connect_reconciles_group_online_membership_when_scope_expands():
    manager = ConnectionManager()
    user_id = uuid.uuid4()
    ws_a = AsyncMock(spec=WebSocket)
    ws_b = AsyncMock(spec=WebSocket)

    with patch("app.ws.manager.add_to_group_online", new_callable=AsyncMock) as add_online:
        with patch(
            "app.ws.manager.remove_from_group_online", new_callable=AsyncMock
        ) as remove_online:
            await manager.connect(ws_a, user_id, ["group-1"])
            await manager.connect(ws_b, user_id, ["group-1", "group-2"])

            assert manager._user_groups[user_id] == ["group-1", "group-2"]
            assert add_online.await_args_list == [
                call("group-1", str(user_id)),
                call("group-2", str(user_id)),
            ]
            remove_online.assert_not_awaited()


@pytest.mark.asyncio
async def test_connect_reconciles_group_online_membership_when_scope_shrinks():
    manager = ConnectionManager()
    user_id = uuid.uuid4()
    ws_a = AsyncMock(spec=WebSocket)
    ws_b = AsyncMock(spec=WebSocket)

    with patch("app.ws.manager.add_to_group_online", new_callable=AsyncMock):
        with patch(
            "app.ws.manager.remove_from_group_online", new_callable=AsyncMock
        ) as remove_online:
            await manager.connect(ws_a, user_id, ["group-1", "group-2"])
            await manager.connect(ws_b, user_id, ["group-1"])

            assert manager._user_groups[user_id] == ["group-1"]
            remove_online.assert_awaited_once_with("group-2", str(user_id))


@pytest.mark.asyncio
async def test_pubsub_listener_recovers_after_transient_exception():
    manager = ConnectionManager()
    events = [
        {
            "type": "ready_changed",
            "group_id": str(uuid.uuid4()),
            "user_id": str(uuid.uuid4()),
        }
    ]

    call_count = 0

    async def flaky_subscribe(_patterns):
        nonlocal call_count
        call_count += 1
        if call_count == 1:
            raise RuntimeError("transient redis failure")
        for event in events:
            yield event
        await asyncio.Event().wait()

    async def noop_sweep() -> None:
        try:
            await asyncio.Event().wait()
        except asyncio.CancelledError:
            raise

    with patch(
        "app.ws.manager.subscribe_to_patterns", side_effect=flaky_subscribe
    ):
        with patch.object(
            manager, "broadcast_event", new_callable=AsyncMock
        ) as broadcast:
            with patch.object(manager, "_run_ready_sweep_loop", noop_sweep):
                with patch(
                    "app.ws.manager._PUBSUB_RETRY_DELAY_SECONDS", 0.01
                ):
                    task = asyncio.create_task(manager.run_pubsub_listener())
                    for _ in range(200):
                        await asyncio.sleep(0.01)
                        if broadcast.await_count >= 1:
                            break
                    task.cancel()
                    with pytest.raises(asyncio.CancelledError):
                        await task

    assert call_count >= 2
    broadcast.assert_awaited_once_with(events[0])
