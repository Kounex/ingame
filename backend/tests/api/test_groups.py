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


async def _create_group_and_get_member(
    client: AsyncClient,
    owner_token: str,
    member_email: str,
    *,
    group_name: str,
):
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(owner_token),
        json={"name": group_name},
    )
    group_id = create_resp.json()["id"]
    invite_code = create_resp.json()["invite_code"]

    member_token = await _register_and_get_token(client, member_email)
    await client.post(
        f"/api/v1/groups/join/{invite_code}",
        headers=_auth(member_token),
    )
    members_resp = await client.get(
        f"/api/v1/groups/{group_id}/members", headers=_auth(owner_token)
    )
    member_user_id = next(
        member["user_id"]
        for member in members_resp.json()
        if member["role"] == "member"
    )
    return group_id, invite_code, member_token, member_user_id


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
async def test_join_by_invite_code_requires_request_for_approval_group(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "approvalowner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token_owner),
        json={"name": "Approval Invite Group", "join_mode": "approval"},
    )
    invite_code = create_resp.json()["invite_code"]
    group_id = create_resp.json()["id"]

    token_joiner = await _register_and_get_token(client, "approvaljoiner@test.com")
    join_resp = await client.post(
        f"/api/v1/groups/join/{invite_code}",
        headers=_auth(token_joiner),
    )
    assert join_resp.status_code == 403
    assert join_resp.json()["code"] == "join_request.required"

    members_resp = await client.get(
        f"/api/v1/groups/{group_id}/members",
        headers=_auth(token_owner),
    )
    assert len(members_resp.json()) == 1


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
    assert response.json()["code"] == "group.member_already_exists"


@pytest.mark.asyncio
async def test_join_by_invite_code_invalid_code_returns_error_code(client: AsyncClient):
    token = await _register_and_get_token(client)

    response = await client.post(
        "/api/v1/groups/join/INVALID1",
        headers=_auth(token),
    )

    assert response.status_code == 404
    assert response.json()["code"] == "group.invite_code_invalid"


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
async def test_non_member_cannot_read_private_group_details(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "privateowner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token_owner),
        json={"name": "Private Group"},
    )
    group_id = create_resp.json()["id"]

    token_stranger = await _register_and_get_token(client, "stranger@test.com")
    response = await client.get(
        f"/api/v1/groups/{group_id}",
        headers=_auth(token_stranger),
    )

    assert response.status_code == 403
    assert response.json()["code"] == "group.member_required"


@pytest.mark.asyncio
async def test_non_member_cannot_list_private_group_members(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "memberowner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token_owner),
        json={"name": "Roster Group"},
    )
    group_id = create_resp.json()["id"]

    token_stranger = await _register_and_get_token(client, "rosterstranger@test.com")
    response = await client.get(
        f"/api/v1/groups/{group_id}/members",
        headers=_auth(token_stranger),
    )

    assert response.status_code == 403
    assert response.json()["code"] == "group.member_required"


@pytest.mark.asyncio
async def test_discover_excludes_member_groups(client: AsyncClient):
    token1 = await _register_and_get_token(client, "disco_owner@test.com")
    await client.post(
        "/api/v1/groups",
        headers=_auth(token1),
        json={"name": "Discoverable Group", "is_discoverable": True},
    )

    token2 = await _register_and_get_token(client, "disco_other@test.com")
    await client.post(
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
async def test_discover_marks_pending_join_requests(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "pending-owner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token_owner),
        json={"name": "Approval Group", "is_discoverable": True, "join_mode": "approval"},
    )
    group_id = create_resp.json()["id"]

    token_requester = await _register_and_get_token(client, "pending-user@test.com")
    request_resp = await client.post(
        f"/api/v1/groups/{group_id}/join-requests",
        headers=_auth(token_requester),
    )
    assert request_resp.status_code == 201

    response = await client.get("/api/v1/groups/discover", headers=_auth(token_requester))
    assert response.status_code == 200

    approval_group = next(group for group in response.json() if group["id"] == group_id)
    assert approval_group["has_pending_join_request"] is True


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
    assert response.json()["code"] == "group.delete_requires_owner"


@pytest.mark.asyncio
async def test_join_request_flow(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "jrowner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token_owner),
        json={
            "name": "Approval Group",
            "is_discoverable": True,
            "join_mode": "approval",
        },
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
async def test_open_group_join_request_is_rejected(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "openjrowner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token_owner),
        json={"name": "Open Group", "is_discoverable": True, "join_mode": "open"},
    )
    group_id = create_resp.json()["id"]

    token_requester = await _register_and_get_token(client, "openjrrequester@test.com")
    req_resp = await client.post(
        f"/api/v1/groups/{group_id}/join-requests",
        headers=_auth(token_requester),
    )

    assert req_resp.status_code == 409
    assert req_resp.json()["code"] == "join_request.not_required"


@pytest.mark.asyncio
async def test_private_approval_group_requires_invite_for_join_request(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "privatejrowner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token_owner),
        json={
            "name": "Private Approval Group",
            "is_discoverable": False,
            "join_mode": "approval",
        },
    )
    group_id = create_resp.json()["id"]
    invite_code = create_resp.json()["invite_code"]

    token_requester = await _register_and_get_token(
        client, "privatejrrequester@test.com"
    )
    raw_req_resp = await client.post(
        f"/api/v1/groups/{group_id}/join-requests",
        headers=_auth(token_requester),
    )
    assert raw_req_resp.status_code == 404
    assert raw_req_resp.json()["code"] == "group.not_found"

    invite_req_resp = await client.post(
        f"/api/v1/groups/join/{invite_code}/requests",
        headers=_auth(token_requester),
    )
    assert invite_req_resp.status_code == 201
    assert invite_req_resp.json()["status"] == "pending"


@pytest.mark.asyncio
async def test_join_request_cannot_be_resolved_twice(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "resolveowner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token_owner),
        json={
            "name": "Resolve Once Group",
            "is_discoverable": True,
            "join_mode": "approval",
        },
    )
    group_id = create_resp.json()["id"]

    token_requester = await _register_and_get_token(
        client, "resolverequester@test.com"
    )
    req_resp = await client.post(
        f"/api/v1/groups/{group_id}/join-requests",
        headers=_auth(token_requester),
    )
    request_id = req_resp.json()["id"]

    approve_resp = await client.patch(
        f"/api/v1/join-requests/{request_id}",
        headers=_auth(token_owner),
        json={"status": "approved"},
    )
    assert approve_resp.status_code == 200

    second_resp = await client.patch(
        f"/api/v1/join-requests/{request_id}",
        headers=_auth(token_owner),
        json={"status": "denied"},
    )
    assert second_resp.status_code == 409
    assert second_resp.json()["code"] == "join_request.already_resolved"

    members_resp = await client.get(
        f"/api/v1/groups/{group_id}/members",
        headers=_auth(token_owner),
    )
    assert len(members_resp.json()) == 2


@pytest.mark.asyncio
async def test_join_request_deny(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "denyowner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token_owner),
        json={"name": "Deny Group", "is_discoverable": True, "join_mode": "approval"},
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


@pytest.mark.asyncio
async def test_non_admin_cannot_list_join_requests_returns_error_code(
    client: AsyncClient,
):
    token_owner = await _register_and_get_token(client, "listowner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token_owner),
        json={"name": "List Requests Group", "join_mode": "approval"},
    )
    group_id = create_resp.json()["id"]

    token_member = await _register_and_get_token(client, "listmember@test.com")
    invite_code = create_resp.json()["invite_code"]
    await client.post(
        f"/api/v1/groups/join/{invite_code}",
        headers=_auth(token_member),
    )

    response = await client.get(
        f"/api/v1/groups/{group_id}/join-requests",
        headers=_auth(token_member),
    )

    assert response.status_code == 403
    assert response.json()["code"] == "join_request.admin_or_owner_required"


@pytest.mark.asyncio
async def test_owner_can_promote_and_demote_member(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "promoteowner@test.com")
    group_id, _, _, member_user_id = await _create_group_and_get_member(
        client,
        token_owner,
        "promotemember@test.com",
        group_name="Promote Group",
    )

    promote_resp = await client.patch(
        f"/api/v1/groups/{group_id}/members/{member_user_id}/role",
        headers=_auth(token_owner),
        json={"role": "admin"},
    )
    assert promote_resp.status_code == 204

    members_resp = await client.get(
        f"/api/v1/groups/{group_id}/members", headers=_auth(token_owner)
    )
    promoted = next(
        member for member in members_resp.json() if member["user_id"] == member_user_id
    )
    assert promoted["role"] == "admin"

    demote_resp = await client.patch(
        f"/api/v1/groups/{group_id}/members/{member_user_id}/role",
        headers=_auth(token_owner),
        json={"role": "member"},
    )
    assert demote_resp.status_code == 204

    members_resp = await client.get(
        f"/api/v1/groups/{group_id}/members", headers=_auth(token_owner)
    )
    demoted = next(
        member for member in members_resp.json() if member["user_id"] == member_user_id
    )
    assert demoted["role"] == "member"


@pytest.mark.asyncio
async def test_admin_cannot_change_member_roles(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "roleowner@test.com")
    group_id, invite_code, admin_token, admin_user_id = await _create_group_and_get_member(
        client,
        token_owner,
        "roleadmin@test.com",
        group_name="Role Group",
    )
    await client.patch(
        f"/api/v1/groups/{group_id}/members/{admin_user_id}/role",
        headers=_auth(token_owner),
        json={"role": "admin"},
    )

    token_target = await _register_and_get_token(client, "roletarget@test.com")
    await client.post(
        f"/api/v1/groups/join/{invite_code}",
        headers=_auth(token_target),
    )
    members_resp = await client.get(
        f"/api/v1/groups/{group_id}/members",
        headers=_auth(token_owner),
    )
    target_user_id = next(
        member["user_id"]
        for member in members_resp.json()
        if member["user_id"] not in {admin_user_id, members_resp.json()[0]["user_id"]}
    )

    response = await client.patch(
        f"/api/v1/groups/{group_id}/members/{target_user_id}/role",
        headers=_auth(admin_token),
        json={"role": "admin"},
    )
    assert response.status_code == 403
    assert response.json()["code"] == "group.owner_required"


@pytest.mark.asyncio
async def test_owner_can_transfer_ownership_and_old_owner_becomes_admin(
    client: AsyncClient,
):
    token_owner = await _register_and_get_token(client, "transferowner@test.com")
    group_id, _, _, member_user_id = await _create_group_and_get_member(
        client,
        token_owner,
        "transfermember@test.com",
        group_name="Transfer Group",
    )

    response = await client.post(
        f"/api/v1/groups/{group_id}/transfer-ownership",
        headers=_auth(token_owner),
        json={"user_id": member_user_id},
    )
    assert response.status_code == 204

    members_resp = await client.get(
        f"/api/v1/groups/{group_id}/members", headers=_auth(token_owner)
    )
    roles_by_user = {
        member["user_id"]: member["role"] for member in members_resp.json()
    }
    owner_membership = next(
        member for member in members_resp.json() if member["role"] == "admin"
    )
    assert roles_by_user[member_user_id] == "owner"
    assert owner_membership["role"] == "admin"


@pytest.mark.asyncio
async def test_admin_cannot_transfer_ownership(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "transferblock@test.com")
    group_id, invite_code, admin_token, admin_user_id = await _create_group_and_get_member(
        client,
        token_owner,
        "transferadmin@test.com",
        group_name="Transfer Block Group",
    )
    await client.patch(
        f"/api/v1/groups/{group_id}/members/{admin_user_id}/role",
        headers=_auth(token_owner),
        json={"role": "admin"},
    )
    token_member = await _register_and_get_token(client, "transfermember2@test.com")
    await client.post(
        f"/api/v1/groups/join/{invite_code}",
        headers=_auth(token_member),
    )
    members_resp = await client.get(
        f"/api/v1/groups/{group_id}/members",
        headers=_auth(token_owner),
    )
    target_user_id = next(
        member["user_id"]
        for member in members_resp.json()
        if member["user_id"] not in {admin_user_id}
        and member["role"] == "member"
    )

    response = await client.post(
        f"/api/v1/groups/{group_id}/transfer-ownership",
        headers=_auth(admin_token),
        json={"user_id": target_user_id},
    )
    assert response.status_code == 403
    assert response.json()["code"] == "group.owner_required"


@pytest.mark.asyncio
async def test_owner_cannot_leave_group_until_ownership_changes(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "leaveowner@test.com")
    create_resp = await client.post(
        "/api/v1/groups",
        headers=_auth(token_owner),
        json={"name": "Leave Group"},
    )
    group_id = create_resp.json()["id"]

    response = await client.delete(
        f"/api/v1/groups/{group_id}/leave",
        headers=_auth(token_owner),
    )
    assert response.status_code == 403
    assert response.json()["code"] == "group.owner_cannot_leave"


@pytest.mark.asyncio
async def test_non_owner_can_leave_group(client: AsyncClient):
    token_owner = await _register_and_get_token(client, "memberleaveowner@test.com")
    group_id, _, member_token, member_user_id = await _create_group_and_get_member(
        client,
        token_owner,
        "memberleave@test.com",
        group_name="Member Leave Group",
    )

    response = await client.delete(
        f"/api/v1/groups/{group_id}/leave",
        headers=_auth(member_token),
    )
    assert response.status_code == 204

    members_resp = await client.get(
        f"/api/v1/groups/{group_id}/members", headers=_auth(token_owner)
    )
    remaining_user_ids = {member["user_id"] for member in members_resp.json()}
    assert member_user_id not in remaining_user_ids
