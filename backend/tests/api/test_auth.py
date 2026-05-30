import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_register_success(client: AsyncClient):
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "test@example.com",
            "password": "securepass123",
            "display_name": "Test User",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["email"] == "test@example.com"
    assert data["user"]["display_name"] == "Test User"


@pytest.mark.asyncio
async def test_register_duplicate_email(client: AsyncClient):
    payload = {
        "email": "dup@example.com",
        "password": "securepass123",
        "display_name": "First User",
    }
    await client.post("/api/v1/auth/register", json=payload)

    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "dup@example.com",
            "password": "anotherpass123",
            "display_name": "Second User",
        },
    )
    assert response.status_code == 409


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient):
    await client.post(
        "/api/v1/auth/register",
        json={
            "email": "login@example.com",
            "password": "securepass123",
            "display_name": "Login User",
        },
    )

    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "login@example.com", "password": "securepass123"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["user"]["email"] == "login@example.com"


@pytest.mark.asyncio
async def test_login_invalid_password(client: AsyncClient):
    await client.post(
        "/api/v1/auth/register",
        json={
            "email": "badlogin@example.com",
            "password": "securepass123",
            "display_name": "User",
        },
    )

    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "badlogin@example.com", "password": "wrongpass"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_login_nonexistent_user(client: AsyncClient):
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "nobody@example.com", "password": "somepass123"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_refresh_success(client: AsyncClient):
    reg_response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "refresh@example.com",
            "password": "securepass123",
            "display_name": "Refresh User",
        },
    )
    refresh_token = reg_response.json()["refresh_token"]

    response = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data


@pytest.mark.asyncio
async def test_refresh_invalid_token(client: AsyncClient):
    response = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": "invalid.token.here"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_check_email_available(client: AsyncClient):
    response = await client.post(
        "/api/v1/auth/check-email",
        json={"value": "fresh@example.com"},
    )
    assert response.status_code == 200
    assert response.json()["available"] is True


@pytest.mark.asyncio
async def test_check_email_taken(client: AsyncClient):
    await client.post(
        "/api/v1/auth/register",
        json={
            "email": "taken@example.com",
            "password": "securepass123",
            "display_name": "Taken",
        },
    )

    response = await client.post(
        "/api/v1/auth/check-email",
        json={"value": "taken@example.com"},
    )
    assert response.status_code == 200
    assert response.json()["available"] is False


@pytest.mark.asyncio
async def test_check_display_name_available(client: AsyncClient):
    response = await client.post(
        "/api/v1/auth/check-display-name",
        json={"value": "UniqueNameXYZ"},
    )
    assert response.status_code == 200
    assert response.json()["available"] is True


@pytest.mark.asyncio
async def test_check_display_name_taken(client: AsyncClient):
    await client.post(
        "/api/v1/auth/register",
        json={
            "email": "dncheck@example.com",
            "password": "securepass123",
            "display_name": "TakenName",
        },
    )

    response = await client.post(
        "/api/v1/auth/check-display-name",
        json={"value": "TakenName"},
    )
    assert response.status_code == 200
    assert response.json()["available"] is False
