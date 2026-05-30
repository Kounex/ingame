import pytest
from httpx import AsyncClient


async def _register_and_get_token(client: AsyncClient, email: str = "groupuser@test.com") -> str:
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "securepass123",
            "display_name": "Group User",
        },
    )
    return response.json()["access_token"]


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_create_group(client: AsyncClient):
    token = await _register_and_get_token(client)
    response = await client.post(
        "/api/v1/groups",
        headers=_auth(token),
        json={"name": "My Gaming Group", "description": "Let's play together"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "My Gaming Group"
    assert data["invite_code"]
    assert data["member_count"] == 1


@pytest.mark.asyncio
async def test_list_user_groups(client: AsyncClient):
    token = await _register_and_get_token(client)
    await client.post(
        "/api/v1/groups",
        headers=_auth(token),
        json={"name": "Group 1"},
    )
    await client.post(
        "/api/v1/groups",
        headers=_auth(token),
        json={"name": "Group 2"},
    )

    response = await client.get("/api/v1/groups", headers=_auth(token))
    assert response.status_code == 200
    assert len(response.json()) == 2


@pytest.mark.asyncio
async def test_join_by_invite_code(client: AsyncClient):
    token1 = await _register_and_get_token(client, "owner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token1),
        json={"name": "Join Test Group"},
    )
    invite_code = create_resp.json()["invite_code"]

    token2 = await _register_and_get_token(client, "joiner@test.com")
    join_resp = await client.post(
        f"/api/v1/groups/join/{invite_code}",
        headers=_auth(token2),
    )
    assert join_resp.status_code == 200
    assert join_resp.json()["member_count"] == 2


@pytest.mark.asyncio
async def test_join_by_invite_code_already_member(client: AsyncClient):
    token = await _register_and_get_token(client)
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token),
        json={"name": "Self Join Test"},
    )
    invite_code = create_resp.json()["invite_code"]

    response = await client.post(
        f"/api/v1/groups/join/{invite_code}",
        headers=_auth(token),
    )
    assert response.status_code == 409


@pytest.mark.asyncio
async def test_list_members(client: AsyncClient):
    token = await _register_and_get_token(client)
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token),
        json={"name": "Members Test"},
    )
    group_id = create_resp.json()["id"]

    response = await client.get(
        f"/api/v1/groups/{group_id}/members", headers=_auth(token)
    )
    assert response.status_code == 200
    members = response.json()
    assert len(members) == 1
    assert members[0]["role"] == "owner"


@pytest.mark.asyncio
async def test_discover_excludes_member_groups(client: AsyncClient):
    token1 = await _register_and_get_token(client, "disco_owner@test.com")
    await client.post(
        "/api/v1/groups",
        headers=_auth(token1),
        json={"name": "Discoverable Group", "is_discoverable": True},
    )

    token2 = await _register_and_get_token(client, "disco_other@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token2),
        json={"name": "My Own Group", "is_discoverable": True},
    )

    response = await client.get("/api/v1/groups/discover", headers=_auth(token2))
    assert response.status_code == 200
    group_names = [g["name"] for g in response.json()]
    assert "Discoverable Group" in group_names
    assert "My Own Group" not in group_names


@pytest.mark.asyncio
async def test_remove_member(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "rmowner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token_owner),
        json={"name": "Remove Test"},
    )
    group_id = create_resp.json()["id"]
    invite_code = create_resp.json()["invite_code"]

    token_member = await _register_and_get_token(client, "rmmember@test.com")
    await client.post(
        f"/api/v1/groups/join/{invite_code}",
        headers=_auth(token_member),
    )

    members_resp = await client.get(
        f"/api/v1/groups/{group_id}/members", headers=_auth(token_owner)
    )
    member_user_id = next(
        m["user_id"] for m in members_resp.json() if m["role"] == "member"
    )

    response = await client.delete(
        f"/api/v1/groups/{group_id}/members/{member_user_id}",
        headers=_auth(token_owner),
    )
    assert response.status_code == 204

    members_after = await client.get(
        f"/api/v1/groups/{group_id}/members", headers=_auth(token_owner)
    )
    assert len(members_after.json()) == 1


@pytest.mark.asyncio
async def test_delete_group(client: AsyncClient):
    token = await _register_and_get_token(client)
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token),
        json={"name": "Delete Me"},
    )
    group_id = create_resp.json()["id"]

    response = await client.delete(
        f"/api/v1/groups/{group_id}", headers=_auth(token)
    )
    assert response.status_code == 204

    get_resp = await client.get(
        f"/api/v1/groups/{group_id}", headers=_auth(token)
    )
    assert get_resp.status_code == 404


@pytest.mark.asyncio
async def test_non_owner_cannot_delete(client: AsyncClient):
    token1 = await _register_and_get_token(client, "delowner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token1),
        json={"name": "Delete Test"},
    )
    group_id = create_resp.json()["id"]
    invite_code = create_resp.json()["invite_code"]

    token2 = await _register_and_get_token(client, "delmember@test.com")
    await client.post(
        f"/api/v1/groups/join/{invite_code}",
        headers=_auth(token2),
    )

    response = await client.delete(
        f"/api/v1/groups/{group_id}", headers=_auth(token2)
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_join_request_flow(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "jrowner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token_owner),
        json={"name": "Approval Group", "join_mode": "approval"},
    )
    group_id = create_resp.json()["id"]

    token_requester = await _register_and_get_token(client, "jrrequester@test.com")
    req_resp = await client.post(
        f"/api/v1/groups/{group_id}/join-requests",
        headers=_auth(token_requester),
    )
    assert req_resp.status_code == 201
    request_id = req_resp.json()["id"]
    assert req_resp.json()["status"] == "pending"

    list_resp = await client.get(
        f"/api/v1/groups/{group_id}/join-requests",
        headers=_auth(token_owner),
    )
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 1
    assert list_resp.json()[0]["id"] == request_id

    resolve_resp = await client.patch(
        f"/api/v1/join-requests/{request_id}",
        headers=_auth(token_owner),
        json={"status": "approved"},
    )
    assert resolve_resp.status_code == 200
    assert resolve_resp.json()["status"] == "approved"

    members_resp = await client.get(
        f"/api/v1/groups/{group_id}/members",
        headers=_auth(token_owner),
    )
    member_roles = {m["role"] for m in members_resp.json()}
    assert "member" in member_roles
    assert len(members_resp.json()) == 2


@pytest.mark.asyncio
async def test_join_request_deny(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "denyowner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token_owner),
        json={"name": "Deny Group", "join_mode": "approval"},
    )
    group_id = create_resp.json()["id"]

    token_requester = await _register_and_get_token(client, "denyrequester@test.com")
    req_resp = await client.post(
        f"/api/v1/groups/{group_id}/join-requests",
        headers=_auth(token_requester),
    )
    request_id = req_resp.json()["id"]

    resolve_resp = await client.patch(
        f"/api/v1/join-requests/{request_id}",
        headers=_auth(token_owner),
        json={"status": "denied"},
    )
    assert resolve_resp.status_code == 200
    assert resolve_resp.json()["status"] == "denied"

    members_resp = await client.get(
        f"/api/v1/groups/{group_id}/members",
        headers=_auth(token_owner),
    )
    assert len(members_resp.json()) == 1
