import httpx
import pytest
from httpx import AsyncClient
from unittest.mock import AsyncMock, patch


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
    assert response.json()["code"] == "auth.email_taken"


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
    assert response.json()["code"] == "auth.invalid_credentials"


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
    assert response.json()["code"] == "auth.refresh_token_invalid"


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


@pytest.mark.asyncio
async def test_apple_auth_success(client: AsyncClient):
    with patch(
        "app.api.v1.auth.service.validate_apple_token",
        new_callable=AsyncMock,
        return_value={"sub": "apple-user-123", "email": "apple@example.com"},
    ):
        response = await client.post(
            "/api/v1/auth/apple",
            json={
                "identity_token": "apple.identity.token",
                "display_name": "René Kounex",
            },
        )

    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["apple_id"] == "apple-user-123"
    assert data["user"]["email"] == "apple@example.com"
    assert data["user"]["display_name"] == "René Kounex"
    assert data["user"]["provider_identities"] == [
        {
            "provider": "apple",
            "auth_mode": "official_oauth",
            "external_id": "apple-user-123",
            "username": None,
            "display_name": None,
            "email": "apple@example.com",
            "avatar_url": None,
            "profile_url": None,
            "metadata": None,
            "last_synced_at": None,
            "supports_login": True,
            "supports_refresh": False,
            "supports_direct_profile_link": False,
            "supports_manual_entry": False,
            "supports_copy_only_action": False,
            "is_social_identity": False,
        }
    ]


@pytest.mark.asyncio
async def test_apple_auth_invalid_token_returns_validation_code(client: AsyncClient):
    with patch(
        "app.api.v1.auth.service.validate_apple_token",
        new_callable=AsyncMock,
        side_effect=ValueError("Apple token verification failed"),
    ):
        response = await client.post(
            "/api/v1/auth/apple",
            json={"identity_token": "invalid.apple.token"},
        )

    assert response.status_code == 422
    assert response.json()["code"] == "auth.apple_token_invalid"


@pytest.mark.asyncio
async def test_discord_auth_success(
    client: AsyncClient, monkeypatch: pytest.MonkeyPatch
):
    monkeypatch.setattr("app.config.settings.discord_client_id", "discord-client-id")

    with (
        patch(
            "app.api.v1.auth.service.exchange_discord_code",
            new_callable=AsyncMock,
            return_value={
                "access_token": "discord-access",
                "refresh_token": "discord-refresh",
                "expires_in": 3600,
            },
        ),
        patch(
            "app.api.v1.auth.service.get_discord_profile",
            new_callable=AsyncMock,
            return_value={
                "external_id": "discord-user-123",
                "username": "discord_user",
                "display_name": "Discord Hero",
                "email": "discord@example.com",
                "avatar_url": "https://cdn.discord.test/avatar.png",
                "profile_url": "https://discord.com/users/discord-user-123",
            },
        ),
    ):
        response = await client.post(
            "/api/v1/auth/discord",
            json={
                "code": "discord-auth-code",
                "code_verifier": "discord-code-verifier-discord-code-verifier-12345",
                "redirect_uri": "ingame://auth/discord/callback",
            },
        )

    assert response.status_code == 200
    data = response.json()
    assert data["user"]["email"] == "discord@example.com"
    assert data["user"]["avatar_url"] == "https://cdn.discord.test/avatar.png"
    assert data["user"]["provider_identities"] == [
        {
            "provider": "discord",
            "auth_mode": "official_oauth",
            "external_id": "discord-user-123",
            "username": "discord_user",
            "display_name": "Discord Hero",
            "email": "discord@example.com",
            "avatar_url": "https://cdn.discord.test/avatar.png",
            "profile_url": "https://discord.com/users/discord-user-123",
            "metadata": None,
            "last_synced_at": data["user"]["provider_identities"][0]["last_synced_at"],
            "supports_login": True,
            "supports_refresh": True,
            "supports_direct_profile_link": True,
            "supports_manual_entry": False,
            "supports_copy_only_action": False,
            "is_social_identity": True,
        }
    ]
    assert data["user"]["provider_identities"][0]["last_synced_at"] is not None


@pytest.mark.asyncio
async def test_discord_auth_does_not_overwrite_existing_profile_avatar(
    client: AsyncClient, monkeypatch: pytest.MonkeyPatch
):
    monkeypatch.setattr("app.config.settings.discord_client_id", "discord-client-id")

    with (
        patch(
            "app.api.v1.auth.service.exchange_discord_code",
            new_callable=AsyncMock,
            return_value={
                "access_token": "discord-access",
                "refresh_token": "discord-refresh",
                "expires_in": 3600,
            },
        ),
        patch(
            "app.api.v1.auth.service.get_discord_profile",
            new_callable=AsyncMock,
            side_effect=[
                {
                    "external_id": "discord-user-456",
                    "username": "discord_user",
                    "display_name": "Discord Hero",
                    "email": "discord2@example.com",
                    "avatar_url": "https://cdn.discord.test/original.png",
                    "profile_url": "https://discord.com/users/discord-user-456",
                },
                {
                    "external_id": "discord-user-456",
                    "username": "discord_user",
                    "display_name": "Discord Hero",
                    "email": "discord2@example.com",
                    "avatar_url": "https://cdn.discord.test/new.png",
                    "profile_url": "https://discord.com/users/discord-user-456",
                },
            ],
        ),
    ):
        first_response = await client.post(
            "/api/v1/auth/discord",
            json={
                "code": "discord-auth-code",
                "code_verifier": "discord-code-verifier-discord-code-verifier-12345",
                "redirect_uri": "ingame://auth/discord/callback",
            },
        )

        token = first_response.json()["access_token"]
        patched = await client.patch(
            "/api/v1/users/me",
            headers={"Authorization": f"Bearer {token}"},
            json={"avatar_url": "https://cdn.example.com/custom-avatar.webp"},
        )
        assert patched.status_code == 200

        second_response = await client.post(
            "/api/v1/auth/discord",
            json={
                "code": "discord-auth-code-2",
                "code_verifier": "discord-code-verifier-discord-code-verifier-12345",
                "redirect_uri": "ingame://auth/discord/callback",
            },
        )

    assert first_response.status_code == 200
    assert second_response.status_code == 200
    assert second_response.json()["user"]["avatar_url"] == (
        "https://cdn.example.com/custom-avatar.webp"
    )
    assert second_response.json()["user"]["provider_identities"][0]["avatar_url"] == (
        "https://cdn.discord.test/new.png"
    )


@pytest.mark.asyncio
async def test_discord_auth_without_backend_client_id_returns_service_unavailable(
    client: AsyncClient, monkeypatch: pytest.MonkeyPatch
):
    monkeypatch.setattr("app.config.settings.discord_client_id", "")

    with patch(
        "app.api.v1.auth.service.exchange_discord_code",
        new_callable=AsyncMock,
    ) as exchange_mock:
        response = await client.post(
            "/api/v1/auth/discord",
            json={
                "code": "discord-auth-code",
                "code_verifier": "discord-code-verifier-discord-code-verifier-12345",
                "redirect_uri": "http://localhost:8090/auth/discord-callback.html",
            },
        )

    assert response.status_code == 503
    assert response.json()["code"] == "auth.discord_unavailable"
    exchange_mock.assert_not_awaited()


@pytest.mark.asyncio
async def test_steam_auth_success(client: AsyncClient):
    with (
        patch(
            "app.api.v1.auth.service.validate_steam_login",
            new_callable=AsyncMock,
            return_value="76561198000000001",
        ),
        patch(
            "app.api.v1.auth.service.get_steam_profile",
            new_callable=AsyncMock,
            return_value={
                "display_name": "Steam User",
                "avatar_url": "https://steamcdn.test/avatar.jpg",
            },
        ),
    ):
        response = await client.post(
            "/api/v1/auth/steam",
            json={
                "openid_params": {
                    "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000001"
                }
            },
        )

    assert response.status_code == 200
    data = response.json()
    assert data["user"]["steam_id"] == "76561198000000001"
    assert data["user"]["display_name"] == "Steam User"
    assert data["user"]["avatar_url"] == "https://steamcdn.test/avatar.jpg"
    assert len(data["user"]["provider_identities"]) == 1
    assert data["user"]["provider_identities"][0] == {
        "provider": "steam",
        "auth_mode": "official_openid",
        "external_id": "76561198000000001",
        "username": None,
        "display_name": "Steam User",
        "email": None,
        "avatar_url": "https://steamcdn.test/avatar.jpg",
        "profile_url": None,
        "metadata": None,
        "last_synced_at": data["user"]["provider_identities"][0]["last_synced_at"],
        "supports_login": True,
        "supports_refresh": True,
        "supports_direct_profile_link": True,
        "supports_manual_entry": False,
        "supports_copy_only_action": False,
        "is_social_identity": True,
    }
    assert data["user"]["provider_identities"][0]["last_synced_at"] is not None


@pytest.mark.asyncio
async def test_steam_auth_does_not_overwrite_existing_profile_avatar(client: AsyncClient):
    with (
        patch(
            "app.api.v1.auth.service.validate_steam_login",
            new_callable=AsyncMock,
            return_value="76561198000000008",
        ),
        patch(
            "app.api.v1.auth.service.get_steam_profile",
            new_callable=AsyncMock,
            side_effect=[
                {
                    "display_name": "Steam User",
                    "avatar_url": "https://steamcdn.test/original.jpg",
                    "profile_url": "https://steamcommunity.com/profiles/76561198000000008",
                },
                {
                    "display_name": "Steam User",
                    "avatar_url": "https://steamcdn.test/new.jpg",
                    "profile_url": "https://steamcommunity.com/profiles/76561198000000008",
                },
            ],
        ),
    ):
        first_response = await client.post(
            "/api/v1/auth/steam",
            json={
                "openid_params": {
                    "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000008"
                }
            },
        )

        token = first_response.json()["access_token"]
        patched = await client.patch(
            "/api/v1/users/me",
            headers={"Authorization": f"Bearer {token}"},
            json={"avatar_url": "https://cdn.example.com/custom-avatar.webp"},
        )
        assert patched.status_code == 200

        second_response = await client.post(
            "/api/v1/auth/steam",
            json={
                "openid_params": {
                    "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000008"
                }
            },
        )

    assert first_response.status_code == 200
    assert second_response.status_code == 200
    assert second_response.json()["user"]["avatar_url"] == (
        "https://cdn.example.com/custom-avatar.webp"
    )
    assert second_response.json()["user"]["provider_identities"][0]["avatar_url"] == (
        "https://steamcdn.test/new.jpg"
    )


@pytest.mark.asyncio
async def test_steam_auth_profile_fetch_failure_returns_structured_error(
    client: AsyncClient,
):
    request = httpx.Request(
        "GET",
        "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/",
    )
    response = httpx.Response(403, request=request)

    with (
        patch(
            "app.api.v1.auth.service.validate_steam_login",
            new_callable=AsyncMock,
            return_value="76561198000000001",
        ),
        patch(
            "app.api.v1.auth.service.get_steam_profile",
            new_callable=AsyncMock,
            side_effect=httpx.HTTPStatusError(
                "Steam profile request failed",
                request=request,
                response=response,
            ),
        ),
    ):
        result = await client.post(
            "/api/v1/auth/steam",
            json={
                "openid_params": {
                    "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000001"
                }
            },
        )

    assert result.status_code == 503
    assert result.json()["code"] == "auth.steam_profile_unavailable"


@pytest.mark.asyncio
async def test_steam_auth_after_unlink_requires_relink_from_profile(client: AsyncClient):
    register = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "steam-relink@example.com",
            "password": "securepass123",
            "display_name": "Steam Relink",
        },
    )
    token = register.json()["access_token"]
    fake_params = {
        "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000007"
    }

    with (
        patch(
            "app.api.v1.users.service.validate_steam_login",
            new_callable=AsyncMock,
            return_value="76561198000000007",
        ),
        patch(
            "app.api.v1.users.service.get_steam_profile",
            new_callable=AsyncMock,
            return_value={
                "display_name": "Steam Relink",
                "avatar_url": "https://steamcdn.test/relink.jpg",
                "profile_url": "https://steamcommunity.com/profiles/76561198000000007",
            },
        ),
    ):
        await client.post(
            "/api/v1/users/me/link-steam",
            headers={"Authorization": f"Bearer {token}"},
            json={"openid_params": fake_params},
        )

    await client.delete(
        "/api/v1/users/me/link-steam",
        headers={"Authorization": f"Bearer {token}"},
    )

    with patch(
        "app.api.v1.auth.service.validate_steam_login",
        new_callable=AsyncMock,
        return_value="76561198000000007",
    ):
        response = await client.post(
            "/api/v1/auth/steam",
            json={"openid_params": fake_params},
        )

    assert response.status_code == 409
    assert response.json()["code"] == "auth.steam_relink_required"


@pytest.mark.asyncio
async def test_apple_auth_after_unlink_requires_relink_from_profile(client: AsyncClient):
    with patch(
        "app.api.v1.auth.service.validate_apple_token",
        new_callable=AsyncMock,
        return_value={"sub": "apple-relink-123", "email": "apple-relink@test.com"},
    ):
        auth_response = await client.post(
            "/api/v1/auth/apple",
            json={
                "identity_token": "apple.identity.token",
                "display_name": "Apple Relink",
            },
        )

    token = auth_response.json()["access_token"]
    unlink = await client.delete(
        "/api/v1/users/me/link-apple",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert unlink.status_code == 422

    set_password = await client.post(
        "/api/v1/users/me/set-email-password",
        headers={"Authorization": f"Bearer {token}"},
        json={"email": "apple-relink@test.com", "password": "securepass123"},
    )
    assert set_password.status_code == 200

    unlink = await client.delete(
        "/api/v1/users/me/link-apple",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert unlink.status_code == 200

    with patch(
        "app.api.v1.auth.service.validate_apple_token",
        new_callable=AsyncMock,
        return_value={"sub": "apple-relink-123", "email": "apple-relink@test.com"},
    ):
        response = await client.post(
            "/api/v1/auth/apple",
            json={"identity_token": "apple.identity.token"},
        )

    assert response.status_code == 409
    assert response.json()["code"] == "auth.apple_relink_required"


@pytest.mark.asyncio
async def test_discord_auth_after_unlink_requires_relink_from_profile(
    client: AsyncClient, monkeypatch: pytest.MonkeyPatch
):
    monkeypatch.setattr("app.config.settings.discord_client_id", "discord-client-id")

    register = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "discord-relink@example.com",
            "password": "securepass123",
            "display_name": "Discord Relink",
        },
    )
    token = register.json()["access_token"]

    with (
        patch(
            "app.api.v1.users.service.exchange_discord_code",
            new_callable=AsyncMock,
            return_value={
                "access_token": "discord-access",
                "refresh_token": "discord-refresh",
                "expires_in": 3600,
            },
        ),
        patch(
            "app.api.v1.users.service.get_discord_profile",
            new_callable=AsyncMock,
            return_value={
                "external_id": "discord-relink-123",
                "username": "discord_relink",
                "display_name": "Discord Relink",
                "email": "discord-relink@example.com",
                "avatar_url": "https://cdn.discord.test/avatar.png",
                "profile_url": "https://discord.com/users/discord-relink-123",
            },
        ),
    ):
        await client.post(
            "/api/v1/users/me/link-discord",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "code": "discord-auth-code",
                "code_verifier": "discord-code-verifier-discord-code-verifier-12345",
                "redirect_uri": "ingame://auth/discord/callback",
            },
        )

    await client.delete(
        "/api/v1/users/me/link-discord",
        headers={"Authorization": f"Bearer {token}"},
    )

    with (
        patch(
            "app.api.v1.auth.service.exchange_discord_code",
            new_callable=AsyncMock,
            return_value={
                "access_token": "discord-access",
                "refresh_token": "discord-refresh",
                "expires_in": 3600,
            },
        ),
        patch(
            "app.api.v1.auth.service.get_discord_profile",
            new_callable=AsyncMock,
            return_value={
                "external_id": "discord-relink-123",
                "username": "discord_relink",
                "display_name": "Discord Relink",
                "email": "discord-relink@example.com",
                "avatar_url": "https://cdn.discord.test/avatar.png",
                "profile_url": "https://discord.com/users/discord-relink-123",
            },
        ),
    ):
        response = await client.post(
            "/api/v1/auth/discord",
            json={
                "code": "discord-auth-code",
                "code_verifier": "discord-code-verifier-discord-code-verifier-12345",
                "redirect_uri": "ingame://auth/discord/callback",
            },
        )

    assert response.status_code == 409
    assert response.json()["code"] == "auth.discord_relink_required"


@pytest.mark.asyncio
async def test_refresh_token_remains_usable_after_unlink(client: AsyncClient):
    register = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "unlink-refresh@example.com",
            "password": "securepass123",
            "display_name": "Refresh After Unlink",
        },
    )
    access_token = register.json()["access_token"]
    refresh_token = register.json()["refresh_token"]
    fake_params = {
        "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000009"
    }

    with (
        patch(
            "app.api.v1.users.service.validate_steam_login",
            new_callable=AsyncMock,
            return_value="76561198000000009",
        ),
        patch(
            "app.api.v1.users.service.get_steam_profile",
            new_callable=AsyncMock,
            return_value={
                "display_name": "Refresh After Unlink",
                "avatar_url": "https://steamcdn.test/unlink-refresh.jpg",
                "profile_url": "https://steamcommunity.com/profiles/76561198000000009",
            },
        ),
    ):
        await client.post(
            "/api/v1/users/me/link-steam",
            headers={"Authorization": f"Bearer {access_token}"},
            json={"openid_params": fake_params},
        )

    unlink = await client.delete(
        "/api/v1/users/me/link-steam",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert unlink.status_code == 200

    refresh = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )

    assert refresh.status_code == 200
    assert "access_token" in refresh.json()
