from unittest.mock import AsyncMock, patch

import pytest
from httpx import AsyncClient


async def _register_and_get_token(client: AsyncClient, email: str = "user@test.com") -> str:
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "securepass123",
            "display_name": "Test User",
        },
    )
    return response.json()["access_token"]


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_get_me(client: AsyncClient):
    token = await _register_and_get_token(client)
    response = await client.get("/api/v1/users/me", headers=_auth(token))
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "user@test.com"
    assert data["display_name"] == "Test User"


@pytest.mark.asyncio
async def test_get_me_unauthorized(client: AsyncClient):
    response = await client.get("/api/v1/users/me")
    assert response.status_code in (401, 403)


@pytest.mark.asyncio
async def test_update_me(client: AsyncClient):
    token = await _register_and_get_token(client)
    response = await client.patch(
        "/api/v1/users/me",
        headers=_auth(token),
        json={"display_name": "Updated Name", "bio": "I love gaming"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["display_name"] == "Updated Name"
    assert data["bio"] == "I love gaming"


@pytest.mark.asyncio
async def test_update_me_partial(client: AsyncClient):
    token = await _register_and_get_token(client)
    response = await client.patch(
        "/api/v1/users/me",
        headers=_auth(token),
        json={"bio": "Just a bio update"},
    )
    assert response.status_code == 200
    assert response.json()["bio"] == "Just a bio update"
    assert response.json()["display_name"] == "Test User"


@pytest.mark.asyncio
async def test_link_steam_success(client: AsyncClient):
    token = await _register_and_get_token(client)

    fake_params = {"openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000001"}

    with patch(
        "app.api.v1.users.service.validate_steam_login",
        new_callable=AsyncMock,
        return_value="76561198000000001",
    ):
        response = await client.post(
            "/api/v1/users/me/link-steam",
            headers=_auth(token),
            json={"openid_params": fake_params},
        )
    assert response.status_code == 200
    assert response.json()["steam_id"] == "76561198000000001"


@pytest.mark.asyncio
async def test_link_steam_conflict(client: AsyncClient):
    token1 = await _register_and_get_token(client, "steam1@test.com")
    token2 = await _register_and_get_token(client, "steam2@test.com")

    fake_params = {"openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000099"}

    with patch(
        "app.api.v1.users.service.validate_steam_login",
        new_callable=AsyncMock,
        return_value="76561198000000099",
    ):
        resp1 = await client.post(
            "/api/v1/users/me/link-steam",
            headers=_auth(token1),
            json={"openid_params": fake_params},
        )
        assert resp1.status_code == 200

        response = await client.post(
            "/api/v1/users/me/link-steam",
            headers=_auth(token2),
            json={"openid_params": fake_params},
        )
    assert response.status_code == 409


@pytest.mark.asyncio
async def test_unlink_steam(client: AsyncClient):
    token = await _register_and_get_token(client)

    fake_params = {"openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000002"}

    with patch(
        "app.api.v1.users.service.validate_steam_login",
        new_callable=AsyncMock,
        return_value="76561198000000002",
    ):
        await client.post(
            "/api/v1/users/me/link-steam",
            headers=_auth(token),
            json={"openid_params": fake_params},
        )

    response = await client.delete("/api/v1/users/me/link-steam", headers=_auth(token))
    assert response.status_code == 200
    assert response.json()["steam_id"] is None


@pytest.mark.asyncio
async def test_get_user_by_id(client: AsyncClient):
    token = await _register_and_get_token(client)
    me_resp = await client.get("/api/v1/users/me", headers=_auth(token))
    user_id = me_resp.json()["id"]

    response = await client.get(f"/api/v1/users/{user_id}", headers=_auth(token))
    assert response.status_code == 200
    assert response.json()["id"] == user_id
