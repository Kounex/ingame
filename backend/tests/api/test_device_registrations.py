import pytest
from httpx import AsyncClient


async def _register_and_get_token(client: AsyncClient, email: str = "notif@test.com") -> str:
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "securepass123", "display_name": "Notif User"},
    )
    return response.json()["access_token"]


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_register_device(client: AsyncClient):
    token = await _register_and_get_token(client)
    response = await client.post(
        "/api/v1/users/me/device-registrations",
        json={"platform": "ios", "token": "fcm-test-token"},
        headers=_auth(token),
    )
    assert response.status_code == 201
    data = response.json()
    assert data["platform"] == "ios"
    assert data["token"] == "fcm-test-token"
    assert "id" in data
    assert "last_seen_at" in data


@pytest.mark.asyncio
async def test_register_device_seeds_preferences(client: AsyncClient):
    token = await _register_and_get_token(client, "seed@test.com")
    await client.post(
        "/api/v1/users/me/device-registrations",
        json={"platform": "ios", "token": "seed-token"},
        headers=_auth(token),
    )

    response = await client.get(
        "/api/v1/users/me/notification-preferences",
        headers=_auth(token),
    )
    assert response.status_code == 200
    prefs = response.json()
    assert len(prefs) == 5


@pytest.mark.asyncio
async def test_register_device_upsert(client: AsyncClient):
    token = await _register_and_get_token(client, "upsert@test.com")
    r1 = await client.post(
        "/api/v1/users/me/device-registrations",
        json={"platform": "ios", "token": "upsert-token"},
        headers=_auth(token),
    )
    r2 = await client.post(
        "/api/v1/users/me/device-registrations",
        json={"platform": "ios", "token": "upsert-token", "device_label": "iPhone"},
        headers=_auth(token),
    )
    assert r1.json()["id"] == r2.json()["id"]
    assert r2.json()["device_label"] == "iPhone"


@pytest.mark.asyncio
async def test_list_device_registrations(client: AsyncClient):
    token = await _register_and_get_token(client, "list@test.com")
    await client.post(
        "/api/v1/users/me/device-registrations",
        json={"platform": "ios", "token": "list-token-1"},
        headers=_auth(token),
    )
    await client.post(
        "/api/v1/users/me/device-registrations",
        json={"platform": "android", "token": "list-token-2"},
        headers=_auth(token),
    )

    response = await client.get(
        "/api/v1/users/me/device-registrations",
        headers=_auth(token),
    )
    assert response.status_code == 200
    assert len(response.json()) == 2


@pytest.mark.asyncio
async def test_delete_device_registration(client: AsyncClient):
    token = await _register_and_get_token(client, "delete@test.com")
    create_response = await client.post(
        "/api/v1/users/me/device-registrations",
        json={"platform": "ios", "token": "delete-token"},
        headers=_auth(token),
    )
    reg_id = create_response.json()["id"]

    delete_response = await client.delete(
        f"/api/v1/users/me/device-registrations/{reg_id}",
        headers=_auth(token),
    )
    assert delete_response.status_code == 204

    list_response = await client.get(
        "/api/v1/users/me/device-registrations",
        headers=_auth(token),
    )
    assert len(list_response.json()) == 0


@pytest.mark.asyncio
async def test_register_device_invalid_platform(client: AsyncClient):
    token = await _register_and_get_token(client, "bad@test.com")
    response = await client.post(
        "/api/v1/users/me/device-registrations",
        json={"platform": "windows", "token": "bad-token"},
        headers=_auth(token),
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_register_device_unauthenticated(client: AsyncClient):
    response = await client.post(
        "/api/v1/users/me/device-registrations",
        json={"platform": "ios", "token": "no-auth-token"},
    )
    assert response.status_code == 401
