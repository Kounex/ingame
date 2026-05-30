import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from starlette.testclient import TestClient
from starlette.websockets import WebSocketDisconnect

from app.auth.jwt import create_access_token
from app.db.models.group import Group, GroupMembership
from app.db.models.user import User
from app.main import app


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
    assert str(user.id) in event["groups"][0]["online_user_ids"]
    assert event["groups"][0]["statuses"][0]["state"] == "online"


@pytest.mark.asyncio
async def test_status_change_is_broadcast_to_other_group_members(
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
                assert owner_online_event == {
                    "type": "user_online",
                    "timestamp": owner_online_event["timestamp"],
                    "group_id": str(group.id),
                    "user_id": str(member.id),
                    "display_name": "Member",
                }

                member_ws.send_json(
                    {"type": "status_change", "state": "ready", "game": "CS2"}
                )
                status_event = owner_ws.receive_json()

    assert status_event["type"] == "status_changed"
    assert status_event["group_id"] == str(group.id)
    assert status_event["user_id"] == str(member.id)
    assert status_event["state"] == "ready"
    assert status_event["game"] == "CS2"
