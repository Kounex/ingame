import asyncio
import time

import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from starlette.testclient import TestClient
from starlette.websockets import WebSocketDisconnect

from app.auth.jwt import create_access_token
from app.db.models.group import Group, GroupMembership
from app.db.models.user import User
from app.main import app
from app.redis import status_store
from app.ws import handlers


async def _create_user(
    db_session: AsyncSession, *, display_name: str, email: str
) -> User:
    user = User(
        email=email,
        display_name=display_name,
        timezone="UTC",
    )
    db_session.add(user)
    await db_session.flush()
    return user


async def _create_group_with_members(
    db_session: AsyncSession,
) -> tuple[User, User, Group]:
    owner = await _create_user(
        db_session,
        display_name="Owner",
        email="owner@example.com",
    )
    member = await _create_user(
        db_session,
        display_name="Member",
        email="member@example.com",
    )

    group = Group(
        name="Raid Night",
        description="Realtime test group",
        invite_code="RAID42",
        created_by=owner.id,
    )
    db_session.add(group)
    await db_session.flush()

    db_session.add_all(
        [
            GroupMembership(group_id=group.id, user_id=owner.id, role="owner"),
            GroupMembership(group_id=group.id, user_id=member.id, role="member"),
        ]
    )
    await db_session.commit()
    return owner, member, group


def test_websocket_no_token():
    with TestClient(app) as tc:
        with pytest.raises(WebSocketDisconnect):
            with tc.websocket_connect("/api/v1/ws"):
                pass


def test_websocket_invalid_token():
    with TestClient(app) as tc:
        with pytest.raises(WebSocketDisconnect):
            with tc.websocket_connect("/api/v1/ws?token=invalid.jwt.token"):
                pass


@pytest.mark.asyncio
async def test_websocket_connect_with_valid_token_receives_presence_snapshot(
    db_session: AsyncSession,
):
    user, _, group = await _create_group_with_members(db_session)
    token = create_access_token(user.id)

    with TestClient(app) as tc:
        with tc.websocket_connect(f"/api/v1/ws?token={token}") as ws:
            event = ws.receive_json()

    assert event["type"] == "presence_snapshot"
    assert len(event["groups"]) == 1
    assert event["groups"][0]["group_id"] == str(group.id)
    members = event["groups"][0]["members"]
    assert len(members) == 1
    assert members[0]["user_id"] == str(user.id)
    assert members[0]["connection"] == "online"
    assert members[0]["ready"] is False


@pytest.mark.asyncio
async def test_ready_toggle_is_broadcast_to_other_group_members(
    db_session: AsyncSession,
):
    owner, member, group = await _create_group_with_members(db_session)
    owner_token = create_access_token(owner.id)
    member_token = create_access_token(member.id)

    with TestClient(app) as tc:
        with tc.websocket_connect(f"/api/v1/ws?token={owner_token}") as owner_ws:
            owner_snapshot = owner_ws.receive_json()
            assert owner_snapshot["type"] == "presence_snapshot"

            with tc.websocket_connect(f"/api/v1/ws?token={member_token}") as member_ws:
                member_snapshot = member_ws.receive_json()
                assert member_snapshot["type"] == "presence_snapshot"

                owner_online_event = owner_ws.receive_json()
                assert owner_online_event["type"] == "user_online"
                assert owner_online_event["group_id"] == str(group.id)
                assert owner_online_event["user_id"] == str(member.id)

                member_ws.send_json(
                    {
                        "type": "ready_toggle",
                        "group_id": str(group.id),
                        "ready": True,
                    }
                )
                ready_event = owner_ws.receive_json()

    assert ready_event["type"] == "ready_changed"
    assert ready_event["group_id"] == str(group.id)
    assert ready_event["user_id"] == str(member.id)
    assert ready_event["ready"] is True
    assert ready_event["ready_since"] is not None
    assert ready_event["ready_expires_at"] is not None


@pytest.mark.asyncio
async def test_presence_lifecycle_away_and_active_broadcast_connection_changed(
    db_session: AsyncSession,
):
    owner, member, group = await _create_group_with_members(db_session)
    owner_token = create_access_token(owner.id)
    member_token = create_access_token(member.id)

    with TestClient(app) as tc:
        with tc.websocket_connect(f"/api/v1/ws?token={owner_token}") as owner_ws:
            owner_ws.receive_json()

            with tc.websocket_connect(f"/api/v1/ws?token={member_token}") as member_ws:
                member_ws.receive_json()
                owner_ws.receive_json()

                member_ws.send_json({"type": "presence_lifecycle", "state": "away"})
                away_event = owner_ws.receive_json()

                member_ws.send_json({"type": "presence_lifecycle", "state": "active"})
                active_event = owner_ws.receive_json()

    assert away_event == {
        "type": "connection_changed",
        "timestamp": away_event["timestamp"],
        "group_id": str(group.id),
        "user_id": str(member.id),
        "connection": "away",
    }
    assert active_event == {
        "type": "connection_changed",
        "timestamp": active_event["timestamp"],
        "group_id": str(group.id),
        "user_id": str(member.id),
        "connection": "online",
    }


@pytest.mark.asyncio
async def test_ready_toggle_off_clears_ready_state(
    db_session: AsyncSession,
):
    owner, member, group = await _create_group_with_members(db_session)
    owner_token = create_access_token(owner.id)
    member_token = create_access_token(member.id)

    with TestClient(app) as tc:
        with tc.websocket_connect(f"/api/v1/ws?token={owner_token}") as owner_ws:
            owner_ws.receive_json()

            with tc.websocket_connect(f"/api/v1/ws?token={member_token}") as member_ws:
                member_ws.receive_json()
                owner_ws.receive_json()

                member_ws.send_json(
                    {
                        "type": "ready_toggle",
                        "group_id": str(group.id),
                        "ready": True,
                    }
                )
                owner_ws.receive_json()

                member_ws.send_json(
                    {
                        "type": "ready_toggle",
                        "group_id": str(group.id),
                        "ready": False,
                    }
                )
                cleared_event = owner_ws.receive_json()

    assert cleared_event["type"] == "ready_changed"
    assert cleared_event["ready"] is False
    assert cleared_event.get("ready_since") is None
    assert cleared_event.get("ready_expires_at") is None


@pytest.mark.asyncio
async def test_expired_ready_is_cleared_on_snapshot_and_broadcast(
    db_session: AsyncSession,
    monkeypatch: pytest.MonkeyPatch,
):
    monkeypatch.setattr(status_store, "READY_TTL_SECONDS", 1)

    owner, member, group = await _create_group_with_members(db_session)
    member_token = create_access_token(member.id)
    owner_token = create_access_token(owner.id)

    with TestClient(app) as tc:
        with tc.websocket_connect(f"/api/v1/ws?token={member_token}") as member_ws:
            member_ws.receive_json()
            member_ws.send_json(
                {
                    "type": "ready_toggle",
                    "group_id": str(group.id),
                    "ready": True,
                }
            )

        await asyncio.sleep(1.1)

        with tc.websocket_connect(f"/api/v1/ws?token={owner_token}") as owner_ws:
            owner_ws.receive_json()

            with tc.websocket_connect(f"/api/v1/ws?token={member_token}") as member_ws:
                snapshot = member_ws.receive_json()
                owner_events = [owner_ws.receive_json(), owner_ws.receive_json()]
                expired_event = next(
                    event
                    for event in owner_events
                    if event["type"] == "ready_changed"
                )

    member_entry = next(
        m
        for m in snapshot["groups"][0]["members"]
        if m["user_id"] == str(member.id)
    )
    assert member_entry["ready"] is False
    assert expired_event["type"] == "ready_changed"
    assert expired_event["user_id"] == str(member.id)
    assert expired_event["ready"] is False


@pytest.mark.asyncio
async def test_ready_persists_across_disconnect_until_cleared(
    db_session: AsyncSession,
):
    owner, member, group = await _create_group_with_members(db_session)
    member_token = create_access_token(member.id)
    owner_token = create_access_token(owner.id)

    with TestClient(app) as tc:
        with tc.websocket_connect(f"/api/v1/ws?token={member_token}") as member_ws:
            member_ws.receive_json()
            member_ws.send_json(
                {
                    "type": "ready_toggle",
                    "group_id": str(group.id),
                    "ready": True,
                }
            )

        with tc.websocket_connect(f"/api/v1/ws?token={owner_token}") as owner_ws:
            snapshot = owner_ws.receive_json()

    member_entry = next(
        m
        for m in snapshot["groups"][0]["members"]
        if m["user_id"] == str(member.id)
    )
    assert member_entry["ready"] is True
    assert member_entry["connection"] == "offline"
    assert member_entry["ready_expires_at"] is not None


@pytest.mark.asyncio
async def test_handle_connect_does_not_republish_ready_state_for_reconnecting_member(
    db_session: AsyncSession,
    monkeypatch: pytest.MonkeyPatch,
):
    owner, member, group = await _create_group_with_members(db_session)
    token = create_access_token(member.id)
    ready_payload = await status_store.set_group_ready(str(group.id), str(member.id))

    published_online: list[tuple[str, str, list[str]]] = []
    published_ready: list[dict[str, object]] = []

    async def fake_connect(websocket, user_id, group_ids):
        return True

    async def fake_sweep_all_groups(group_ids):
        return None

    async def fake_send_presence_snapshot(user_id, group_ids, websocket):
        return None

    async def fake_publish_user_online(user_id, display_name, group_ids):
        published_online.append((str(user_id), display_name, group_ids))

    async def fake_publish_ready_changed(
        user_id,
        group_id,
        *,
        ready,
        ready_since=None,
        ready_expires_at=None,
    ):
        published_ready.append(
            {
                "user_id": str(user_id),
                "group_id": group_id,
                "ready": ready,
                "ready_since": ready_since,
                "ready_expires_at": ready_expires_at,
            }
        )

    monkeypatch.setattr(handlers.manager, "connect", fake_connect)
    monkeypatch.setattr(handlers.manager, "sweep_all_groups", fake_sweep_all_groups)
    monkeypatch.setattr(
        handlers.manager,
        "send_presence_snapshot",
        fake_send_presence_snapshot,
    )
    monkeypatch.setattr(
        handlers.manager,
        "publish_user_online",
        fake_publish_user_online,
    )
    monkeypatch.setattr(
        handlers.manager,
        "publish_ready_changed",
        fake_publish_ready_changed,
    )

    user_id = await handlers.handle_connect(object(), token)

    assert user_id == member.id
    assert published_online == [(str(member.id), member.display_name, [str(group.id)])]
    assert published_ready == []


@pytest.mark.asyncio
async def test_legacy_status_change_is_ignored(
    db_session: AsyncSession,
):
    owner, member, group = await _create_group_with_members(db_session)
    owner_token = create_access_token(owner.id)
    member_token = create_access_token(member.id)

    with TestClient(app) as tc:
        with tc.websocket_connect(f"/api/v1/ws?token={owner_token}") as owner_ws:
            owner_ws.receive_json()

            with tc.websocket_connect(f"/api/v1/ws?token={member_token}") as member_ws:
                member_ws.receive_json()
                owner_ws.receive_json()
                member_ws.send_json({"type": "status_change", "state": "ready"})

    ready = await status_store.get_group_ready(str(group.id), str(member.id))
    assert ready is None


@pytest.mark.asyncio
async def test_closing_one_of_two_connections_does_not_broadcast_user_offline(
    db_session: AsyncSession,
):
    owner, member, group = await _create_group_with_members(db_session)
    owner_token = create_access_token(owner.id)
    member_token = create_access_token(member.id)

    with TestClient(app) as tc:
        with tc.websocket_connect(f"/api/v1/ws?token={owner_token}") as owner_ws:
            owner_ws.receive_json()

            with tc.websocket_connect(f"/api/v1/ws?token={member_token}") as member_ws_a:
                member_ws_a.receive_json()
                owner_ws.receive_json()

                with tc.websocket_connect(
                    f"/api/v1/ws?token={member_token}"
                ) as member_ws_b:
                    member_ws_b.receive_json()

                    member_ws_a.close()

                    member_ws_b.send_json(
                        {"type": "presence_lifecycle", "state": "away"}
                    )
                    away_event = owner_ws.receive_json()

    assert away_event["type"] == "connection_changed"
    assert away_event["user_id"] == str(member.id)
    assert away_event["connection"] == "away"


@pytest.mark.asyncio
async def test_closing_last_connection_broadcasts_user_offline(
    db_session: AsyncSession,
):
    owner, member, group = await _create_group_with_members(db_session)
    owner_token = create_access_token(owner.id)
    member_token = create_access_token(member.id)

    with TestClient(app) as tc:
        with tc.websocket_connect(f"/api/v1/ws?token={owner_token}") as owner_ws:
            owner_ws.receive_json()

            with tc.websocket_connect(f"/api/v1/ws?token={member_token}") as member_ws:
                member_ws.receive_json()
                owner_ws.receive_json()

            offline_event = owner_ws.receive_json()

    assert offline_event == {
        "type": "user_offline",
        "timestamp": offline_event["timestamp"],
        "group_id": str(group.id),
        "user_id": str(member.id),
    }
