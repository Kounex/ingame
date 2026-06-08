from datetime import datetime, timedelta, timezone

import pytest
from httpx import AsyncClient

from app.api.v1.coordination import service as coordination_service


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def _parse_iso(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


async def _register_and_get_token(
    client: AsyncClient,
    *,
    email: str,
    display_name: str,
) -> str:
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "securepass123",
            "display_name": display_name,
        },
    )
    return response.json()["access_token"]


async def _create_group_with_member(
    client: AsyncClient,
) -> tuple[str, str, str]:
    owner_token = await _register_and_get_token(
        client,
        email="coord-owner@test.com",
        display_name="Coord Owner",
    )
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(owner_token),
        json={"name": "Coordination Group"},
    )
    group_id = create_resp.json()["id"]
    invite_code = create_resp.json()["invite_code"]

    member_token = await _register_and_get_token(
        client,
        email="coord-member@test.com",
        display_name="Coord Member",
    )
    await client.post(
        f"/api/v1/groups/join/{invite_code}",
        headers=_auth(member_token),
    )

    return group_id, owner_token, member_token


async def _create_session(
    client: AsyncClient,
    *,
    group_id: str,
    token: str,
    starts_at: datetime,
    title: str = "Valheim Night",
) -> dict:
    response = await client.post(
        f"/api/v1/groups/{group_id}/sessions",
        headers=_auth(token),
        json={
            "title": title,
            "game": "Valheim",
            "starts_at": starts_at.isoformat(),
        },
    )
    assert response.status_code == 201
    return response.json()


@pytest.mark.asyncio
async def test_scheduled_ready_crud_flow(client: AsyncClient):
    group_id, owner_token, _ = await _create_group_with_member(client)
    starts_at = datetime.now(timezone.utc).replace(microsecond=0) + timedelta(days=1)
    ends_at = starts_at + timedelta(hours=2)

    create_resp = await client.post(
        f"/api/v1/groups/{group_id}/scheduled-ready",
        headers=_auth(owner_token),
        json={
            "starts_at": starts_at.isoformat(),
            "ends_at": ends_at.isoformat(),
        },
    )
    assert create_resp.status_code == 201
    window = create_resp.json()
    assert window["group_id"] == group_id
    assert _parse_iso(window["starts_at"]) == starts_at
    assert _parse_iso(window["ends_at"]) == ends_at
    assert window["source"] == "manual"

    list_resp = await client.get(
        f"/api/v1/groups/{group_id}/scheduled-ready",
        headers=_auth(owner_token),
    )
    assert list_resp.status_code == 200
    assert [item["id"] for item in list_resp.json()] == [window["id"]]

    updated_end = ends_at + timedelta(hours=1)
    update_resp = await client.patch(
        f"/api/v1/groups/{group_id}/scheduled-ready/{window['id']}",
        headers=_auth(owner_token),
        json={"ends_at": updated_end.isoformat()},
    )
    assert update_resp.status_code == 200
    assert _parse_iso(update_resp.json()["ends_at"]) == updated_end

    delete_resp = await client.delete(
        f"/api/v1/groups/{group_id}/scheduled-ready/{window['id']}",
        headers=_auth(owner_token),
    )
    assert delete_resp.status_code == 204

    list_after_delete = await client.get(
        f"/api/v1/groups/{group_id}/scheduled-ready",
        headers=_auth(owner_token),
    )
    assert list_after_delete.status_code == 200
    assert list_after_delete.json() == []


@pytest.mark.asyncio
async def test_member_cannot_edit_someone_elses_scheduled_ready_window(
    client: AsyncClient,
):
    group_id, owner_token, member_token = await _create_group_with_member(client)
    starts_at = datetime.now(timezone.utc).replace(microsecond=0) + timedelta(days=1)
    ends_at = starts_at + timedelta(hours=2)

    create_resp = await client.post(
        f"/api/v1/groups/{group_id}/scheduled-ready",
        headers=_auth(owner_token),
        json={
            "starts_at": starts_at.isoformat(),
            "ends_at": ends_at.isoformat(),
        },
    )
    window_id = create_resp.json()["id"]

    update_resp = await client.patch(
        f"/api/v1/groups/{group_id}/scheduled-ready/{window_id}",
        headers=_auth(member_token),
        json={"ends_at": (ends_at + timedelta(hours=1)).isoformat()},
    )
    assert update_resp.status_code == 403

    delete_resp = await client.delete(
        f"/api/v1/groups/{group_id}/scheduled-ready/{window_id}",
        headers=_auth(member_token),
    )
    assert delete_resp.status_code == 403


@pytest.mark.asyncio
async def test_scheduled_ready_window_must_be_in_the_future(client: AsyncClient):
    group_id, owner_token, _ = await _create_group_with_member(client)
    starts_at = datetime.now(timezone.utc).replace(microsecond=0) - timedelta(hours=2)
    ends_at = starts_at + timedelta(hours=1)

    create_resp = await client.post(
        f"/api/v1/groups/{group_id}/scheduled-ready",
        headers=_auth(owner_token),
        json={
            "starts_at": starts_at.isoformat(),
            "ends_at": ends_at.isoformat(),
        },
    )

    assert create_resp.status_code == 403


@pytest.mark.asyncio
async def test_commit_failure_prevents_session_fanout(
    client: AsyncClient,
    db_session,
    monkeypatch: pytest.MonkeyPatch,
):
    group_id, owner_token, _ = await _create_group_with_member(client)
    starts_at = datetime.now(timezone.utc).replace(microsecond=0) + timedelta(days=2)
    published: list[tuple[str, dict]] = []

    async def fake_publish_session_proposed(payload: dict) -> None:
        published.append(("session_proposed", payload))

    async def fake_publish_activity_recorded(payload: dict) -> None:
        published.append(("activity_recorded", payload))

    async def failing_commit() -> None:
        raise RuntimeError("commit failed")

    monkeypatch.setattr(
        coordination_service.manager,
        "publish_session_proposed",
        fake_publish_session_proposed,
    )
    monkeypatch.setattr(
        coordination_service.manager,
        "publish_activity_recorded",
        fake_publish_activity_recorded,
    )
    monkeypatch.setattr(db_session, "commit", failing_commit)

    with pytest.raises(RuntimeError, match="commit failed"):
        await client.post(
            f"/api/v1/groups/{group_id}/sessions",
            headers=_auth(owner_token),
            json={
                "title": "Valheim Night",
                "game": "Valheim",
                "starts_at": starts_at.isoformat(),
            },
        )

    assert published == []


@pytest.mark.asyncio
async def test_post_commit_publish_failure_does_not_fail_session_create(
    client: AsyncClient,
    monkeypatch: pytest.MonkeyPatch,
):
    group_id, owner_token, _ = await _create_group_with_member(client)
    starts_at = datetime.now(timezone.utc).replace(microsecond=0) + timedelta(days=2)

    async def failing_publish_session_proposed(payload: dict) -> None:
        raise RuntimeError("publish failed")

    async def failing_publish_activity_recorded(payload: dict) -> None:
        raise RuntimeError("publish failed")

    monkeypatch.setattr(
        coordination_service.manager,
        "publish_session_proposed",
        failing_publish_session_proposed,
    )
    monkeypatch.setattr(
        coordination_service.manager,
        "publish_activity_recorded",
        failing_publish_activity_recorded,
    )

    create_resp = await client.post(
        f"/api/v1/groups/{group_id}/sessions",
        headers=_auth(owner_token),
        json={
            "title": "Resilient Session",
            "game": "Valheim",
            "starts_at": starts_at.isoformat(),
        },
    )

    assert create_resp.status_code == 201
    created_session = create_resp.json()

    list_resp = await client.get(
        f"/api/v1/groups/{group_id}/sessions",
        headers=_auth(owner_token),
    )
    assert list_resp.status_code == 200
    assert [item["id"] for item in list_resp.json()] == [created_session["id"]]


@pytest.mark.asyncio
async def test_owner_can_update_another_members_session(client: AsyncClient):
    group_id, owner_token, member_token = await _create_group_with_member(client)
    starts_at = datetime.now(timezone.utc).replace(microsecond=0) + timedelta(days=2)
    session = await _create_session(
        client,
        group_id=group_id,
        token=member_token,
        starts_at=starts_at,
        title="Late Raid",
    )

    update_resp = await client.patch(
        f"/api/v1/groups/{group_id}/sessions/{session['id']}",
        headers=_auth(owner_token),
        json={"status": "confirmed", "notes": "Owner locked the time"},
    )

    assert update_resp.status_code == 200
    assert update_resp.json()["status"] == "confirmed"
    assert update_resp.json()["notes"] == "Owner locked the time"


@pytest.mark.asyncio
async def test_session_delete_removes_it_from_list_and_records_activity(client: AsyncClient):
    group_id, owner_token, _ = await _create_group_with_member(client)
    starts_at = datetime.now(timezone.utc).replace(microsecond=0) + timedelta(days=2)
    session = await _create_session(
        client,
        group_id=group_id,
        token=owner_token,
        starts_at=starts_at,
    )

    delete_resp = await client.delete(
        f"/api/v1/groups/{group_id}/sessions/{session['id']}",
        headers=_auth(owner_token),
    )
    assert delete_resp.status_code == 204

    list_resp = await client.get(
        f"/api/v1/groups/{group_id}/sessions",
        headers=_auth(owner_token),
    )
    assert list_resp.status_code == 200
    assert list_resp.json() == []

    activity_resp = await client.get(
        f"/api/v1/groups/{group_id}/activity",
        headers=_auth(owner_token),
    )
    assert activity_resp.status_code == 200
    activity_types = [item["type"] for item in activity_resp.json()]
    assert "session_deleted" in activity_types


@pytest.mark.asyncio
async def test_member_cannot_delete_someone_elses_session(client: AsyncClient):
    group_id, owner_token, member_token = await _create_group_with_member(client)
    starts_at = datetime.now(timezone.utc).replace(microsecond=0) + timedelta(days=2)
    session = await _create_session(
        client,
        group_id=group_id,
        token=owner_token,
        starts_at=starts_at,
    )

    delete_resp = await client.delete(
        f"/api/v1/groups/{group_id}/sessions/{session['id']}",
        headers=_auth(member_token),
    )

    assert delete_resp.status_code == 403


@pytest.mark.asyncio
async def test_non_member_cannot_access_group_coordination(client: AsyncClient):
    group_id, owner_token, _ = await _create_group_with_member(client)
    outsider_token = await _register_and_get_token(
        client,
        email="coord-outsider@test.com",
        display_name="Coord Outsider",
    )

    sessions_resp = await client.get(
        f"/api/v1/groups/{group_id}/sessions",
        headers=_auth(outsider_token),
    )
    activity_resp = await client.get(
        f"/api/v1/groups/{group_id}/activity",
        headers=_auth(outsider_token),
    )

    assert sessions_resp.status_code == 403
    assert activity_resp.status_code == 403


@pytest.mark.asyncio
async def test_invalid_session_update_and_rsvp_payloads_are_rejected(client: AsyncClient):
    group_id, owner_token, member_token = await _create_group_with_member(client)
    starts_at = datetime.now(timezone.utc).replace(microsecond=0) + timedelta(days=2)
    session = await _create_session(
        client,
        group_id=group_id,
        token=owner_token,
        starts_at=starts_at,
    )

    update_resp = await client.patch(
        f"/api/v1/groups/{group_id}/sessions/{session['id']}",
        headers=_auth(owner_token),
        json={"starts_at": (starts_at - timedelta(days=3)).isoformat()},
    )
    invalid_status_resp = await client.patch(
        f"/api/v1/groups/{group_id}/sessions/{session['id']}",
        headers=_auth(owner_token),
        json={"status": "done"},
    )
    invalid_rsvp_resp = await client.post(
        f"/api/v1/groups/{group_id}/sessions/{session['id']}/rsvp",
        headers=_auth(member_token),
        json={"response": "later"},
    )

    assert update_resp.status_code == 403
    assert invalid_status_resp.status_code == 422
    assert invalid_rsvp_resp.status_code == 422


@pytest.mark.asyncio
async def test_sessions_rsvp_and_activity_feed_flow(client: AsyncClient):
    group_id, owner_token, member_token = await _create_group_with_member(client)
    starts_at = datetime.now(timezone.utc).replace(microsecond=0) + timedelta(days=2)

    create_session = await client.post(
        f"/api/v1/groups/{group_id}/sessions",
        headers=_auth(owner_token),
        json={
            "title": "Valheim Night",
            "game": "Valheim",
            "starts_at": starts_at.isoformat(),
            "notes": "Bring your best Viking energy",
        },
    )
    assert create_session.status_code == 201
    session = create_session.json()
    assert session["group_id"] == group_id
    assert session["status"] == "proposed"
    assert session["rsvps"] == []

    rsvp_resp = await client.post(
        f"/api/v1/groups/{group_id}/sessions/{session['id']}/rsvp",
        headers=_auth(member_token),
        json={"response": "maybe"},
    )
    assert rsvp_resp.status_code == 200
    assert rsvp_resp.json()["response"] == "maybe"

    list_sessions = await client.get(
        f"/api/v1/groups/{group_id}/sessions",
        headers=_auth(owner_token),
    )
    assert list_sessions.status_code == 200
    listed_session = list_sessions.json()[0]
    assert listed_session["id"] == session["id"]
    assert listed_session["rsvps"][0]["response"] == "maybe"

    activity_resp = await client.get(
        f"/api/v1/groups/{group_id}/activity",
        headers=_auth(owner_token),
    )
    assert activity_resp.status_code == 200
    activity_types = [item["type"] for item in activity_resp.json()]
    assert "session_proposed" in activity_types
    assert "session_rsvp_updated" in activity_types
