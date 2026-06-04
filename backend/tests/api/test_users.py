from unittest.mock import AsyncMock, patch
from types import SimpleNamespace
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import text

from app.storage.avatar_uploads import generate_avatar_upload
async def _register_and_get_token(
    client: AsyncClient, email: str = "user@test.com"
) -> str:
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
    assert data["has_password_login"] is True


@pytest.mark.asyncio
async def test_get_me_for_apple_only_user_marks_password_login_disconnected(
    client: AsyncClient,
):
    with patch(
        "app.api.v1.auth.service.validate_apple_token",
        new_callable=AsyncMock,
        return_value={"sub": "apple-only-123", "email": "apple-only@test.com"},
    ):
        auth_response = await client.post(
            "/api/v1/auth/apple",
            json={
                "identity_token": "apple.identity.token",
                "display_name": "Apple Only",
            },
        )

    token = auth_response.json()["access_token"]
    response = await client.get("/api/v1/users/me", headers=_auth(token))

    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "apple-only@test.com"
    assert data["apple_id"] == "apple-only-123"
    assert data["has_password_login"] is False


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
async def test_update_me_can_clear_avatar_url(client: AsyncClient):
    token = await _register_and_get_token(client)

    seeded = await client.patch(
        "/api/v1/users/me",
        headers=_auth(token),
        json={"avatar_url": "https://cdn.example.com/original-avatar.webp"},
    )
    assert seeded.status_code == 200
    assert seeded.json()["avatar_url"] == "https://cdn.example.com/original-avatar.webp"

    response = await client.patch(
        "/api/v1/users/me",
        headers=_auth(token),
        json={"avatar_url": None},
    )

    assert response.status_code == 200
    assert response.json()["avatar_url"] is None


@pytest.mark.asyncio
async def test_avatar_upload_init_returns_presigned_upload_contract(
    client: AsyncClient,
):
    token = await _register_and_get_token(client)

    with patch(
        "app.api.v1.users.service.generate_avatar_upload",
        return_value={
            "upload_url": "https://uploads.test/bucket",
            "upload_fields": {"key": "users/test/avatars/avatar.webp"},
            "object_key": "users/test/avatars/avatar.webp",
            "avatar_url": "https://cdn.test/users/test/avatars/avatar.webp",
            "expires_in_seconds": 300,
            "max_file_size_bytes": 2097152,
            "allowed_content_types": ["image/jpeg", "image/png", "image/webp"],
        },
    ) as generate_upload:
        response = await client.post(
            "/api/v1/users/me/avatar-upload/init",
            headers=_auth(token),
            json={
                "filename": "avatar.webp",
                "content_type": "image/webp",
                "byte_size": 182000,
            },
        )

    assert response.status_code == 200
    assert response.json() == {
        "upload_url": "https://uploads.test/bucket",
        "upload_fields": {"key": "users/test/avatars/avatar.webp"},
        "object_key": "users/test/avatars/avatar.webp",
        "avatar_url": "https://cdn.test/users/test/avatars/avatar.webp",
        "expires_in_seconds": 300,
        "max_file_size_bytes": 2097152,
        "allowed_content_types": ["image/jpeg", "image/png", "image/webp"],
    }
    generate_upload.assert_called_once()


@pytest.mark.asyncio
async def test_avatar_upload_init_rejects_unsupported_content_type(client: AsyncClient):
    token = await _register_and_get_token(client)

    response = await client.post(
        "/api/v1/users/me/avatar-upload/init",
        headers=_auth(token),
        json={
            "filename": "avatar.gif",
            "content_type": "image/gif",
            "byte_size": 182000,
        },
    )

    assert response.status_code == 422
    assert response.json()["code"] == "user.avatar_content_type_invalid"


@pytest.mark.asyncio
async def test_avatar_upload_init_rejects_oversize_file(client: AsyncClient):
    token = await _register_and_get_token(client)

    response = await client.post(
        "/api/v1/users/me/avatar-upload/init",
        headers=_auth(token),
        json={
            "filename": "avatar.webp",
            "content_type": "image/webp",
            "byte_size": 8 * 1024 * 1024,
        },
    )

    assert response.status_code == 422
    assert response.json()["code"] == "user.avatar_file_too_large"


@pytest.mark.asyncio
async def test_avatar_upload_init_presign_failure_returns_structured_error(
    client: AsyncClient,
):
    token = await _register_and_get_token(client)

    class _FailingPresignClient:
        def generate_presigned_post(self, *args, **kwargs):
            raise RuntimeError("presign failed")

    with (
        patch("app.storage.avatar_uploads.settings.avatar_storage_bucket", "avatars"),
        patch(
            "app.storage.avatar_uploads.settings.avatar_storage_public_base_url",
            "https://cdn.test",
        ),
        patch(
            "app.storage.avatar_uploads._avatar_upload_client",
            return_value=_FailingPresignClient(),
        ),
    ):
        response = await client.post(
            "/api/v1/users/me/avatar-upload/init",
            headers=_auth(token),
            json={
                "filename": "avatar.webp",
                "content_type": "image/webp",
                "byte_size": 182000,
            },
        )

    assert response.status_code == 503
    assert response.json()["code"] == "user.avatar_upload_unavailable"


def test_generate_avatar_upload_rewrites_upload_url_for_browser_access():
    class _PresignClient:
        def generate_presigned_post(self, *args, **kwargs):
            return {
                "url": "http://minio:9000/ingame-avatars",
                "fields": {"key": "users/test/avatars/avatar.png"},
            }

    settings_stub = SimpleNamespace(
        avatar_storage_bucket="ingame-avatars",
        avatar_storage_public_base_url="http://localhost:9000/ingame-avatars",
        avatar_storage_upload_base_url="http://localhost:9000",
        avatar_upload_max_file_size_bytes=2097152,
        avatar_upload_presign_expires_seconds=300,
    )

    with (
        patch("app.storage.avatar_uploads.settings", settings_stub),
        patch(
            "app.storage.avatar_uploads._avatar_upload_client",
            return_value=_PresignClient(),
        ),
    ):
        result = generate_avatar_upload(
            user_id=uuid4(),
            content_type="image/png",
        )

    assert result["upload_url"] == "http://localhost:9000/ingame-avatars"
    assert result["avatar_url"].startswith("http://localhost:9000/ingame-avatars/")


@pytest.mark.asyncio
async def test_update_me_can_set_recovery_email(client: AsyncClient):
    with (
        patch(
            "app.api.v1.auth.service.validate_steam_login",
            new_callable=AsyncMock,
            return_value="76561198000000123",
        ),
        patch(
            "app.api.v1.auth.service.get_steam_profile",
            new_callable=AsyncMock,
            return_value={
                "display_name": "Steam Only",
                "avatar_url": "https://steamcdn.test/avatar.jpg",
            },
        ),
    ):
        auth_response = await client.post(
            "/api/v1/auth/steam",
            json={
                "openid_params": {
                    "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000123"
                }
            },
        )

    token = auth_response.json()["access_token"]
    response = await client.patch(
        "/api/v1/users/me",
        headers=_auth(token),
        json={"email": "steam-recovery@test.com"},
    )

    assert response.status_code == 200
    assert response.json()["email"] == "steam-recovery@test.com"
    assert response.json()["has_password_login"] is False


@pytest.mark.asyncio
async def test_update_me_rejects_duplicate_recovery_email(client: AsyncClient):
    await client.post(
        "/api/v1/auth/register",
        json={
            "email": "taken-recovery@test.com",
            "password": "securepass123",
            "display_name": "Taken Recovery",
        },
    )

    with (
        patch(
            "app.api.v1.auth.service.validate_steam_login",
            new_callable=AsyncMock,
            return_value="76561198000000124",
        ),
        patch(
            "app.api.v1.auth.service.get_steam_profile",
            new_callable=AsyncMock,
            return_value={
                "display_name": "Steam Only",
                "avatar_url": "https://steamcdn.test/avatar.jpg",
            },
        ),
    ):
        auth_response = await client.post(
            "/api/v1/auth/steam",
            json={
                "openid_params": {
                    "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000124"
                }
            },
        )

    token = auth_response.json()["access_token"]
    response = await client.patch(
        "/api/v1/users/me",
        headers=_auth(token),
        json={"email": "taken-recovery@test.com"},
    )

    assert response.status_code == 409
    assert response.json()["code"] == "user.email_taken"


@pytest.mark.asyncio
async def test_link_steam_success(client: AsyncClient):
    token = await _register_and_get_token(client)

    fake_params = {
        "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000001"
    }

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

    fake_params = {
        "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000099"
    }

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
    assert response.json()["code"] == "user.steam_account_already_linked"


@pytest.mark.asyncio
async def test_link_apple_success(client: AsyncClient):
    token = await _register_and_get_token(client)

    with patch(
        "app.api.v1.users.service.validate_apple_token",
        new_callable=AsyncMock,
        return_value={"sub": "apple-link-123", "email": "apple-link@test.com"},
    ):
        response = await client.post(
            "/api/v1/users/me/link-apple",
            headers=_auth(token),
            json={"identity_token": "apple.identity.token"},
        )

    assert response.status_code == 200
    assert response.json()["apple_id"] == "apple-link-123"


@pytest.mark.asyncio
async def test_link_apple_conflict(client: AsyncClient):
    token1 = await _register_and_get_token(client, "apple1@test.com")
    token2 = await _register_and_get_token(client, "apple2@test.com")

    with patch(
        "app.api.v1.users.service.validate_apple_token",
        new_callable=AsyncMock,
        return_value={"sub": "apple-conflict-123", "email": "apple-conflict@test.com"},
    ):
        resp1 = await client.post(
            "/api/v1/users/me/link-apple",
            headers=_auth(token1),
            json={"identity_token": "apple.identity.token"},
        )
        assert resp1.status_code == 200

        response = await client.post(
            "/api/v1/users/me/link-apple",
            headers=_auth(token2),
            json={"identity_token": "apple.identity.token"},
        )

    assert response.status_code == 409
    assert response.json()["code"] == "user.apple_account_already_linked"


@pytest.mark.asyncio
async def test_get_me_invalid_token_returns_error_code(client: AsyncClient):
    response = await client.get(
        "/api/v1/users/me", headers={"Authorization": "Bearer invalid.token.value"}
    )
    assert response.status_code == 401
    assert response.json()["code"] == "auth.access_token_invalid"


@pytest.mark.asyncio
async def test_link_steam_invalid_openid_returns_validation_code(client: AsyncClient):
    token = await _register_and_get_token(client)

    with patch(
        "app.api.v1.users.service.validate_steam_login",
        new_callable=AsyncMock,
        side_effect=ValueError("Steam OpenID validation failed"),
    ):
        response = await client.post(
            "/api/v1/users/me/link-steam",
            headers=_auth(token),
            json={"openid_params": {"openid.mode": "cancel"}},
        )

    assert response.status_code == 422
    assert response.json()["code"] == "auth.steam_openid_invalid"


@pytest.mark.asyncio
async def test_link_apple_invalid_token_returns_validation_code(client: AsyncClient):
    token = await _register_and_get_token(client)

    with patch(
        "app.api.v1.users.service.validate_apple_token",
        new_callable=AsyncMock,
        side_effect=ValueError("Apple token verification failed"),
    ):
        response = await client.post(
            "/api/v1/users/me/link-apple",
            headers=_auth(token),
            json={"identity_token": "invalid.apple.token"},
        )

    assert response.status_code == 422
    assert response.json()["code"] == "auth.apple_token_invalid"


@pytest.mark.asyncio
async def test_unlink_steam(client: AsyncClient):
    token = await _register_and_get_token(client)

    fake_params = {
        "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000002"
    }

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
async def test_unlink_steam_records_revoked_provider_identity(
    client: AsyncClient, db_session
):
    token = await _register_and_get_token(client)
    fake_params = {
        "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000002"
    }

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
    result = await db_session.execute(
        text(
            "select provider, external_id from revoked_auth_links "
            "where provider = 'steam' and external_id = '76561198000000002'"
        )
    )
    assert result.one() == ("steam", "76561198000000002")


@pytest.mark.asyncio
async def test_unlink_apple(client: AsyncClient):
    token = await _register_and_get_token(client)

    with patch(
        "app.api.v1.users.service.validate_apple_token",
        new_callable=AsyncMock,
        return_value={"sub": "apple-unlink-123", "email": "apple-unlink@test.com"},
    ):
        await client.post(
            "/api/v1/users/me/link-apple",
            headers=_auth(token),
            json={"identity_token": "apple.identity.token"},
        )

    response = await client.delete("/api/v1/users/me/link-apple", headers=_auth(token))
    assert response.status_code == 200
    assert response.json()["apple_id"] is None


@pytest.mark.asyncio
async def test_unlink_apple_records_revoked_provider_identity(
    client: AsyncClient, db_session
):
    token = await _register_and_get_token(client)

    with patch(
        "app.api.v1.users.service.validate_apple_token",
        new_callable=AsyncMock,
        return_value={"sub": "apple-unlink-123", "email": "apple-unlink@test.com"},
    ):
        await client.post(
            "/api/v1/users/me/link-apple",
            headers=_auth(token),
            json={"identity_token": "apple.identity.token"},
        )

    response = await client.delete("/api/v1/users/me/link-apple", headers=_auth(token))

    assert response.status_code == 200
    result = await db_session.execute(
        text(
            "select provider, external_id from revoked_auth_links "
            "where provider = 'apple' and external_id = 'apple-unlink-123'"
        )
    )
    assert result.one() == ("apple", "apple-unlink-123")


@pytest.mark.asyncio
async def test_relink_steam_clears_revoked_provider_identity(
    client: AsyncClient, db_session
):
    token = await _register_and_get_token(client)
    fake_params = {
        "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000002"
    }

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
        await client.delete("/api/v1/users/me/link-steam", headers=_auth(token))
        relink = await client.post(
            "/api/v1/users/me/link-steam",
            headers=_auth(token),
            json={"openid_params": fake_params},
        )

    assert relink.status_code == 200
    result = await db_session.execute(
        text(
            "select count(*) from revoked_auth_links "
            "where provider = 'steam' and external_id = '76561198000000002'"
        )
    )
    assert result.scalar_one() == 0


@pytest.mark.asyncio
async def test_unlink_steam_only_auth_method_returns_error_code(client: AsyncClient):
    token = await _register_and_get_token(client)

    response = await client.delete("/api/v1/users/me/link-steam", headers=_auth(token))

    assert response.status_code == 422
    assert response.json()["code"] == "user.last_auth_method_required"


@pytest.mark.asyncio
async def test_unlink_apple_only_auth_method_returns_error_code(client: AsyncClient):
    with patch(
        "app.api.v1.auth.service.validate_apple_token",
        new_callable=AsyncMock,
        return_value={"sub": "apple-only-123", "email": "apple-only@test.com"},
    ):
        response = await client.post(
            "/api/v1/auth/apple",
            json={"identity_token": "apple.only.auth.token"},
        )

    token = response.json()["access_token"]
    unlink = await client.delete("/api/v1/users/me/link-apple", headers=_auth(token))

    assert unlink.status_code == 422
    assert unlink.json()["code"] == "user.last_auth_method_required"


@pytest.mark.asyncio
async def test_get_user_by_id(client: AsyncClient):
    token = await _register_and_get_token(client)
    me_resp = await client.get("/api/v1/users/me", headers=_auth(token))
    user_id = me_resp.json()["id"]

    response = await client.get(f"/api/v1/users/{user_id}", headers=_auth(token))
    assert response.status_code == 200
    assert response.json()["id"] == user_id
