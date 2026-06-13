import logging
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, patch
from types import SimpleNamespace
from uuid import uuid4

import pytest
import httpx
from httpx import AsyncClient
from sqlalchemy import text

from app.db.repositories.avatar_upload_ledger_repo import AvatarUploadLedgerRepository
from app.jobs.avatar_upload_janitor import run_avatar_upload_janitor_once
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
    assert data["provider_identities"] == []


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
    assert data["provider_identities"] == [
        {
            "provider": "apple",
            "auth_mode": "official_oauth",
            "external_id": "apple-only-123",
            "username": None,
            "display_name": None,
            "email": "apple-only@test.com",
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
async def test_update_me_replacing_managed_avatar_deletes_previous_object(
    client: AsyncClient,
):
    token = await _register_and_get_token(client)
    old_avatar_url = "https://cdn.test/ingame-avatars/users/test/avatars/original.webp"
    new_avatar_url = "https://cdn.test/ingame-avatars/users/test/avatars/updated.webp"

    with (
        patch(
            "app.storage.avatar_uploads.settings.avatar_storage_public_base_url",
            "https://cdn.test/ingame-avatars",
        ),
        patch("app.storage.avatar_uploads.settings.avatar_storage_bucket", "ingame-avatars"),
        patch(
            "app.api.v1.users.service.delete_avatar_object_by_public_url",
            create=True,
        ) as delete_avatar,
    ):
        seeded = await client.patch(
            "/api/v1/users/me",
            headers=_auth(token),
            json={"avatar_url": old_avatar_url},
        )
        response = await client.patch(
            "/api/v1/users/me",
            headers=_auth(token),
            json={"avatar_url": new_avatar_url},
        )

    assert seeded.status_code == 200
    assert response.status_code == 200
    assert response.json()["avatar_url"] == new_avatar_url
    delete_avatar.assert_called_once_with(old_avatar_url)


@pytest.mark.asyncio
async def test_update_me_clearing_managed_avatar_deletes_previous_object(
    client: AsyncClient,
):
    token = await _register_and_get_token(client)
    old_avatar_url = "https://cdn.test/ingame-avatars/users/test/avatars/original.webp"

    with (
        patch(
            "app.storage.avatar_uploads.settings.avatar_storage_public_base_url",
            "https://cdn.test/ingame-avatars",
        ),
        patch("app.storage.avatar_uploads.settings.avatar_storage_bucket", "ingame-avatars"),
        patch(
            "app.api.v1.users.service.delete_avatar_object_by_public_url",
            create=True,
        ) as delete_avatar,
    ):
        seeded = await client.patch(
            "/api/v1/users/me",
            headers=_auth(token),
            json={"avatar_url": old_avatar_url},
        )
        response = await client.patch(
            "/api/v1/users/me",
            headers=_auth(token),
            json={"avatar_url": None},
        )

    assert seeded.status_code == 200
    assert response.status_code == 200
    assert response.json()["avatar_url"] is None
    delete_avatar.assert_called_once_with(old_avatar_url)


@pytest.mark.asyncio
async def test_update_me_replacing_external_avatar_does_not_delete_it(
    client: AsyncClient,
):
    token = await _register_and_get_token(client)
    external_avatar_url = "https://steamcdn.test/avatar.jpg"
    new_managed_avatar_url = (
        "https://cdn.test/ingame-avatars/users/test/avatars/updated.webp"
    )

    with (
        patch(
            "app.storage.avatar_uploads.settings.avatar_storage_public_base_url",
            "https://cdn.test/ingame-avatars",
        ),
        patch("app.storage.avatar_uploads.settings.avatar_storage_bucket", "ingame-avatars"),
        patch(
            "app.api.v1.users.service.delete_avatar_object_by_public_url",
            create=True,
        ) as delete_avatar,
    ):
        seeded = await client.patch(
            "/api/v1/users/me",
            headers=_auth(token),
            json={"avatar_url": external_avatar_url},
        )
        response = await client.patch(
            "/api/v1/users/me",
            headers=_auth(token),
            json={"avatar_url": new_managed_avatar_url},
        )

    assert seeded.status_code == 200
    assert response.status_code == 200
    assert response.json()["avatar_url"] == new_managed_avatar_url
    delete_avatar.assert_not_called()


@pytest.mark.asyncio
async def test_update_me_avatar_cleanup_failure_does_not_fail_request(
    client: AsyncClient,
    caplog: pytest.LogCaptureFixture,
):
    token = await _register_and_get_token(client)
    old_avatar_url = "https://cdn.test/ingame-avatars/users/test/avatars/original.webp"
    new_avatar_url = "https://cdn.test/ingame-avatars/users/test/avatars/updated.webp"

    caplog.set_level(logging.ERROR, logger="app.api.v1.users.routes")

    with (
        patch(
            "app.storage.avatar_uploads.settings.avatar_storage_public_base_url",
            "https://cdn.test/ingame-avatars",
        ),
        patch("app.storage.avatar_uploads.settings.avatar_storage_bucket", "ingame-avatars"),
        patch(
            "app.api.v1.users.service.delete_avatar_object_by_public_url",
            side_effect=RuntimeError("cleanup failed"),
            create=True,
        ) as delete_avatar,
    ):
        seeded = await client.patch(
            "/api/v1/users/me",
            headers=_auth(token),
            json={"avatar_url": old_avatar_url},
        )
        response = await client.patch(
            "/api/v1/users/me",
            headers=_auth(token),
            json={"avatar_url": new_avatar_url},
        )
        refreshed = await client.get("/api/v1/users/me", headers=_auth(token))

    assert seeded.status_code == 200
    assert response.status_code == 200
    assert response.json()["avatar_url"] == new_avatar_url
    assert refreshed.status_code == 200
    assert refreshed.json()["avatar_url"] == new_avatar_url
    delete_avatar.assert_called_once_with(old_avatar_url)
    assert "Avatar cleanup failed" in caplog.text


@pytest.mark.asyncio
async def test_update_me_replacing_managed_avatar_sweeps_user_avatar_prefix(
    client: AsyncClient,
):
    token = await _register_and_get_token(client)
    old_avatar_url = "https://cdn.test/ingame-avatars/users/test/avatars/original.webp"
    new_avatar_url = "https://cdn.test/ingame-avatars/users/test/avatars/updated.webp"

    with (
        patch(
            "app.storage.avatar_uploads.settings.avatar_storage_public_base_url",
            "https://cdn.test/ingame-avatars",
        ),
        patch("app.storage.avatar_uploads.settings.avatar_storage_bucket", "ingame-avatars"),
        patch(
            "app.api.v1.users.service.delete_avatar_object_by_public_url",
            create=True,
        ),
        patch(
            "app.api.v1.users.service.sweep_user_avatar_prefix",
            create=True,
        ) as sweep_avatar_prefix,
    ):
        await client.patch(
            "/api/v1/users/me",
            headers=_auth(token),
            json={"avatar_url": old_avatar_url},
        )
        response = await client.patch(
            "/api/v1/users/me",
            headers=_auth(token),
            json={"avatar_url": new_avatar_url},
        )

    assert response.status_code == 200
    assert response.json()["avatar_url"] == new_avatar_url
    sweep_avatar_prefix.assert_called()
    assert sweep_avatar_prefix.call_args.args[1] == new_avatar_url


@pytest.mark.asyncio
async def test_update_me_clearing_managed_avatar_sweeps_whole_user_avatar_prefix(
    client: AsyncClient,
):
    token = await _register_and_get_token(client)
    old_avatar_url = "https://cdn.test/ingame-avatars/users/test/avatars/original.webp"

    with (
        patch(
            "app.storage.avatar_uploads.settings.avatar_storage_public_base_url",
            "https://cdn.test/ingame-avatars",
        ),
        patch("app.storage.avatar_uploads.settings.avatar_storage_bucket", "ingame-avatars"),
        patch(
            "app.api.v1.users.service.delete_avatar_object_by_public_url",
            create=True,
        ),
        patch(
            "app.api.v1.users.service.sweep_user_avatar_prefix",
            create=True,
        ) as sweep_avatar_prefix,
    ):
        await client.patch(
            "/api/v1/users/me",
            headers=_auth(token),
            json={"avatar_url": old_avatar_url},
        )
        response = await client.patch(
            "/api/v1/users/me",
            headers=_auth(token),
            json={"avatar_url": None},
        )

    assert response.status_code == 200
    assert response.json()["avatar_url"] is None
    sweep_avatar_prefix.assert_called()
    assert sweep_avatar_prefix.call_args.args[1] is None


@pytest.mark.asyncio
async def test_update_me_without_avatar_url_does_not_sweep_user_avatar_prefix(
    client: AsyncClient,
):
    token = await _register_and_get_token(client)

    with patch(
        "app.api.v1.users.service.sweep_user_avatar_prefix",
        create=True,
    ) as sweep_avatar_prefix:
        response = await client.patch(
            "/api/v1/users/me",
            headers=_auth(token),
            json={"display_name": "Updated Name"},
        )

    assert response.status_code == 200
    sweep_avatar_prefix.assert_not_called()


@pytest.mark.asyncio
async def test_update_me_avatar_sweep_failure_does_not_fail_request(
    client: AsyncClient,
    caplog: pytest.LogCaptureFixture,
):
    token = await _register_and_get_token(client)
    old_avatar_url = "https://cdn.test/ingame-avatars/users/test/avatars/original.webp"
    new_avatar_url = "https://cdn.test/ingame-avatars/users/test/avatars/updated.webp"

    with (
        patch(
            "app.storage.avatar_uploads.settings.avatar_storage_public_base_url",
            "https://cdn.test/ingame-avatars",
        ),
        patch("app.storage.avatar_uploads.settings.avatar_storage_bucket", "ingame-avatars"),
        patch(
            "app.api.v1.users.service.delete_avatar_object_by_public_url",
            create=True,
        ),
        patch(
            "app.api.v1.users.service.sweep_user_avatar_prefix",
            create=True,
        ),
    ):
        await client.patch(
            "/api/v1/users/me",
            headers=_auth(token),
            json={"avatar_url": old_avatar_url},
        )

    caplog.set_level(logging.ERROR, logger="app.api.v1.users.routes")

    with (
        patch(
            "app.storage.avatar_uploads.settings.avatar_storage_public_base_url",
            "https://cdn.test/ingame-avatars",
        ),
        patch("app.storage.avatar_uploads.settings.avatar_storage_bucket", "ingame-avatars"),
        patch(
            "app.api.v1.users.service.delete_avatar_object_by_public_url",
            create=True,
        ),
        patch(
            "app.api.v1.users.service.sweep_user_avatar_prefix",
            side_effect=RuntimeError("sweep failed"),
            create=True,
        ) as sweep_avatar_prefix,
    ):
        response = await client.patch(
            "/api/v1/users/me",
            headers=_auth(token),
            json={"avatar_url": new_avatar_url},
        )
        refreshed = await client.get("/api/v1/users/me", headers=_auth(token))

    assert response.status_code == 200
    assert response.json()["avatar_url"] == new_avatar_url
    assert refreshed.status_code == 200
    assert refreshed.json()["avatar_url"] == new_avatar_url
    sweep_avatar_prefix.assert_called_once()
    assert "Avatar cleanup failed" in caplog.text


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
async def test_avatar_upload_init_records_pending_ledger_entry(
    client: AsyncClient,
    db_session,
):
    token = await _register_and_get_token(client)
    user_response = await client.get("/api/v1/users/me", headers=_auth(token))
    user_id = user_response.json()["id"]

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

    assert response.status_code == 200
    ledger = await AvatarUploadLedgerRepository(db_session).get_by_avatar_url(
        "https://cdn.test/users/test/avatars/avatar.webp"
    )
    assert ledger is not None
    assert str(ledger.user_id) == user_id
    assert ledger.object_key == "users/test/avatars/avatar.webp"
    assert ledger.committed_at is None


@pytest.mark.asyncio
async def test_update_me_marks_pending_avatar_upload_committed(
    client: AsyncClient,
    db_session,
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
    ):
        init_response = await client.post(
            "/api/v1/users/me/avatar-upload/init",
            headers=_auth(token),
            json={
                "filename": "avatar.webp",
                "content_type": "image/webp",
                "byte_size": 182000,
            },
        )

    avatar_url = init_response.json()["avatar_url"]
    response = await client.patch(
        "/api/v1/users/me",
        headers=_auth(token),
        json={"avatar_url": avatar_url},
    )

    assert init_response.status_code == 200
    assert response.status_code == 200
    assert response.json()["avatar_url"] == avatar_url
    ledger = await AvatarUploadLedgerRepository(db_session).get_by_avatar_url(avatar_url)
    assert ledger is not None
    assert ledger.committed_at is not None


@pytest.mark.asyncio
async def test_avatar_upload_janitor_preserves_provider_avatar_when_custom_upload_expires(
    client: AsyncClient,
    db_session,
    monkeypatch: pytest.MonkeyPatch,
):
    provider_avatar_url = "https://cdn.discord.test/provider-avatar.png"
    custom_object_key = "users/test/avatars/abandoned.webp"
    custom_avatar_url = f"https://cdn.test/{custom_object_key}"
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
                "external_id": "discord-user-ttl",
                "username": "discord_user",
                "display_name": "Discord TTL",
                "email": "discord-ttl@example.com",
                "avatar_url": provider_avatar_url,
                "profile_url": "https://discord.com/users/discord-user-ttl",
            },
        ),
    ):
        auth_response = await client.post(
            "/api/v1/auth/discord",
            json={
                "code": "discord-auth-code",
                "code_verifier": "discord-code-verifier-discord-code-verifier-12345",
                "redirect_uri": "ingame://auth/discord/callback",
            },
        )

    token = auth_response.json()["access_token"]
    assert auth_response.status_code == 200
    assert auth_response.json()["user"]["avatar_url"] == provider_avatar_url

    with patch(
        "app.api.v1.users.service.generate_avatar_upload",
        return_value={
            "upload_url": "https://uploads.test/bucket",
            "upload_fields": {"key": custom_object_key},
            "object_key": custom_object_key,
            "avatar_url": custom_avatar_url,
            "expires_in_seconds": 300,
            "max_file_size_bytes": 2097152,
            "allowed_content_types": ["image/jpeg", "image/png", "image/webp"],
        },
    ):
        init_response = await client.post(
            "/api/v1/users/me/avatar-upload/init",
            headers=_auth(token),
            json={
                "filename": "avatar.webp",
                "content_type": "image/webp",
                "byte_size": 182000,
            },
        )

    assert init_response.status_code == 200
    await db_session.execute(
        text(
            "update avatar_upload_ledgers "
            "set created_at = :created_at "
            "where avatar_url = :avatar_url"
        ),
        {
            "created_at": datetime.now(timezone.utc) - timedelta(days=2),
            "avatar_url": custom_avatar_url,
        },
    )
    await db_session.commit()

    with patch("app.jobs.avatar_upload_janitor.delete_avatar_object_by_key") as delete_avatar:
        deleted_count = await run_avatar_upload_janitor_once(db_session)

    me_response = await client.get("/api/v1/users/me", headers=_auth(token))

    assert deleted_count == 1
    assert me_response.status_code == 200
    assert me_response.json()["avatar_url"] == provider_avatar_url
    delete_avatar.assert_called_once_with(custom_object_key)
    ledger = await AvatarUploadLedgerRepository(db_session).get_by_avatar_url(
        custom_avatar_url
    )
    assert ledger is None


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

    with (
        patch(
            "app.api.v1.users.service.validate_steam_login",
            new_callable=AsyncMock,
            return_value="76561198000000001",
        ),
        patch(
            "app.api.v1.users.service.get_steam_profile",
            new_callable=AsyncMock,
            return_value={
                "display_name": "Steam User",
                "avatar_url": "https://steamcdn.test/avatar.jpg",
                "profile_url": "https://steamcommunity.com/profiles/76561198000000001",
            },
        ),
    ):
        response = await client.post(
            "/api/v1/users/me/link-steam",
            headers=_auth(token),
            json={"openid_params": fake_params},
        )
    assert response.status_code == 200
    assert response.json()["steam_id"] == "76561198000000001"
    assert response.json()["avatar_url"] == "https://steamcdn.test/avatar.jpg"
    identities = response.json()["provider_identities"]
    assert len(identities) == 1
    assert identities[0]["provider"] == "steam"
    assert identities[0]["external_id"] == "76561198000000001"
    assert identities[0]["supports_login"] is True
    assert identities[0]["is_social_identity"] is True
    assert identities[0]["avatar_url"] == "https://steamcdn.test/avatar.jpg"
    assert (
        identities[0]["profile_url"]
        == "https://steamcommunity.com/profiles/76561198000000001"
    )


@pytest.mark.asyncio
async def test_get_me_refreshes_stale_steam_identity(client: AsyncClient, db_session):
    token = await _register_and_get_token(client)
    fake_params = {
        "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000011"
    }

    with (
        patch(
            "app.api.v1.users.service.validate_steam_login",
            new_callable=AsyncMock,
            return_value="76561198000000011",
        ),
        patch(
            "app.api.v1.users.service.get_steam_profile",
            new_callable=AsyncMock,
            return_value={
                "display_name": "Steam Linked",
                "avatar_url": "https://steamcdn.test/linked.jpg",
                "profile_url": "https://steamcommunity.com/profiles/76561198000000011",
            },
        ),
    ):
        await client.post(
            "/api/v1/users/me/link-steam",
            headers=_auth(token),
            json={"openid_params": fake_params},
        )

    await db_session.execute(
        text(
            "update provider_identities set last_synced_at = '2020-01-01T00:00:00+00:00' "
            "where provider = 'steam'"
        )
    )
    await db_session.commit()

    with patch(
        "app.api.v1.users.service.get_steam_profile",
        new_callable=AsyncMock,
        return_value={
            "display_name": "Steam Refreshed",
            "avatar_url": "https://steamcdn.test/refreshed.jpg",
            "profile_url": "https://steamcommunity.com/profiles/76561198000000011",
        },
    ):
        response = await client.get("/api/v1/users/me", headers=_auth(token))

    assert response.status_code == 200
    identities = response.json()["provider_identities"]
    assert identities[0]["provider"] == "steam"
    assert identities[0]["display_name"] == "Steam Refreshed"
    assert identities[0]["avatar_url"] == "https://steamcdn.test/refreshed.jpg"
    assert identities[0]["profile_url"] == "https://steamcommunity.com/profiles/76561198000000011"


@pytest.mark.asyncio
async def test_link_steam_conflict(client: AsyncClient):
    token1 = await _register_and_get_token(client, "steam1@test.com")
    token2 = await _register_and_get_token(client, "steam2@test.com")

    fake_params = {
        "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000099"
    }

    with (
        patch(
            "app.api.v1.users.service.validate_steam_login",
            new_callable=AsyncMock,
            return_value="76561198000000099",
        ),
        patch(
            "app.api.v1.users.service.get_steam_profile",
            new_callable=AsyncMock,
            return_value={
                "display_name": "Steam Conflict",
                "avatar_url": "https://steamcdn.test/conflict.jpg",
                "profile_url": "https://steamcommunity.com/profiles/76561198000000099",
            },
        ),
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
async def test_link_steam_profile_fetch_failure_returns_structured_error(
    client: AsyncClient,
):
    token = await _register_and_get_token(client)
    fake_params = {
        "openid.claimed_id": "https://steamcommunity.com/openid/id/76561198000000999"
    }

    request = httpx.Request(
        "GET",
        "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/",
    )
    response = httpx.Response(403, request=request)

    with (
        patch(
            "app.api.v1.users.service.validate_steam_login",
            new_callable=AsyncMock,
            return_value="76561198000000999",
        ),
        patch(
            "app.api.v1.users.service.get_steam_profile",
            new_callable=AsyncMock,
            side_effect=httpx.HTTPStatusError(
                "Steam profile request failed",
                request=request,
                response=response,
            ),
        ),
    ):
        result = await client.post(
            "/api/v1/users/me/link-steam",
            headers=_auth(token),
            json={"openid_params": fake_params},
        )

    assert result.status_code == 503
    assert result.json()["code"] == "auth.steam_profile_unavailable"


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
async def test_link_discord_success(client: AsyncClient):
    token = await _register_and_get_token(client)

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
                "external_id": "discord-link-123",
                "username": "discord_link",
                "display_name": "Discord Link",
                "email": "discord-link@test.com",
                "avatar_url": "https://cdn.discord.test/avatar.png",
                "profile_url": "https://discord.com/users/discord-link-123",
            },
        ),
    ):
        response = await client.post(
            "/api/v1/users/me/link-discord",
            headers=_auth(token),
            json={
                "code": "discord-auth-code",
                "code_verifier": "discord-code-verifier-discord-code-verifier-12345",
                "redirect_uri": "ingame://auth/discord/callback",
            },
        )

    assert response.status_code == 200
    assert response.json()["avatar_url"] == "https://cdn.discord.test/avatar.png"
    identities = response.json()["provider_identities"]
    assert len(identities) == 1
    assert identities[0]["provider"] == "discord"
    assert identities[0]["external_id"] == "discord-link-123"
    assert identities[0]["supports_login"] is True


@pytest.mark.asyncio
async def test_get_me_refreshes_stale_discord_identity(client: AsyncClient, db_session):
    token = await _register_and_get_token(client)

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
                "external_id": "discord-refresh-123",
                "username": "discord_refresh",
                "display_name": "Discord First",
                "email": "discord-refresh@test.com",
                "avatar_url": "https://cdn.discord.test/first.png",
                "profile_url": "https://discord.com/users/discord-refresh-123",
            },
        ),
    ):
        await client.post(
            "/api/v1/users/me/link-discord",
            headers=_auth(token),
            json={
                "code": "discord-auth-code",
                "code_verifier": "discord-code-verifier-discord-code-verifier-12345",
                "redirect_uri": "ingame://auth/discord/callback",
            },
        )

    await db_session.execute(
        text(
            "update provider_identities set last_synced_at = '2020-01-01T00:00:00+00:00' "
            "where provider = 'discord'"
        )
    )
    await db_session.commit()

    with (
        patch(
            "app.api.v1.users.service.refresh_discord_token",
            new_callable=AsyncMock,
            return_value={
                "access_token": "discord-access-2",
                "refresh_token": "discord-refresh-2",
                "expires_in": 7200,
            },
        ),
        patch(
            "app.api.v1.users.service.get_discord_profile",
            new_callable=AsyncMock,
            return_value={
                "external_id": "discord-refresh-123",
                "username": "discord_refresh",
                "display_name": "Discord Refreshed",
                "email": "discord-refresh@test.com",
                "avatar_url": "https://cdn.discord.test/refreshed.png",
                "profile_url": "https://discord.com/users/discord-refresh-123",
            },
        ),
    ):
        response = await client.get("/api/v1/users/me", headers=_auth(token))

    assert response.status_code == 200
    identities = response.json()["provider_identities"]
    assert identities[0]["provider"] == "discord"
    assert identities[0]["display_name"] == "Discord Refreshed"
    assert identities[0]["avatar_url"] == "https://cdn.discord.test/refreshed.png"


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

    with (
        patch(
            "app.api.v1.users.service.validate_steam_login",
            new_callable=AsyncMock,
            return_value="76561198000000002",
        ),
        patch(
            "app.api.v1.users.service.get_steam_profile",
            new_callable=AsyncMock,
            return_value={
                "display_name": "Steam Unlink",
                "avatar_url": "https://steamcdn.test/unlink.jpg",
                "profile_url": "https://steamcommunity.com/profiles/76561198000000002",
            },
        ),
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

    with (
        patch(
            "app.api.v1.users.service.validate_steam_login",
            new_callable=AsyncMock,
            return_value="76561198000000002",
        ),
        patch(
            "app.api.v1.users.service.get_steam_profile",
            new_callable=AsyncMock,
            return_value={
                "display_name": "Steam Revoked",
                "avatar_url": "https://steamcdn.test/revoked.jpg",
                "profile_url": "https://steamcommunity.com/profiles/76561198000000002",
            },
        ),
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
async def test_upsert_manual_xbox_identity(client: AsyncClient):
    token = await _register_and_get_token(client)

    response = await client.put(
        "/api/v1/users/me/social-identities/xbox",
        headers=_auth(token),
        json={"username": "MasterChief117"},
    )

    assert response.status_code == 200
    identities = response.json()["provider_identities"]
    assert len(identities) == 1
    assert identities[0] == {
        "provider": "xbox",
        "auth_mode": "manual_unverified",
        "external_id": "MasterChief117",
        "username": "MasterChief117",
        "display_name": None,
        "email": None,
        "avatar_url": None,
        "profile_url": "https://account.xbox.com/en-us/profile?gamertag=MasterChief117",
        "metadata": None,
        "last_synced_at": None,
        "supports_login": False,
        "supports_refresh": False,
        "supports_direct_profile_link": True,
        "supports_manual_entry": True,
        "supports_copy_only_action": False,
        "is_social_identity": True,
    }


@pytest.mark.asyncio
async def test_upsert_manual_playstation_identity(client: AsyncClient):
    token = await _register_and_get_token(client)

    response = await client.put(
        "/api/v1/users/me/social-identities/playstation",
        headers=_auth(token),
        json={
            "username": "PSHero",
            "profile_url": "https://profile.playstation.com/PSHero",
        },
    )

    assert response.status_code == 200
    identities = response.json()["provider_identities"]
    assert len(identities) == 1
    assert identities[0]["provider"] == "playstation"
    assert identities[0]["username"] == "PSHero"
    assert identities[0]["profile_url"] == "https://profile.playstation.com/PSHero"
    assert identities[0]["supports_direct_profile_link"] is True
    assert identities[0]["supports_manual_entry"] is True


@pytest.mark.asyncio
async def test_upsert_manual_nintendo_identity(client: AsyncClient):
    token = await _register_and_get_token(client)

    response = await client.put(
        "/api/v1/users/me/social-identities/nintendo",
        headers=_auth(token),
        json={
            "external_id": "SW-1234-5678-9012",
            "display_name": "Switch Buddy",
        },
    )

    assert response.status_code == 200
    identities = response.json()["provider_identities"]
    assert len(identities) == 1
    assert identities[0] == {
        "provider": "nintendo",
        "auth_mode": "manual_unverified",
        "external_id": "SW-1234-5678-9012",
        "username": None,
        "display_name": "Switch Buddy",
        "email": None,
        "avatar_url": None,
        "profile_url": None,
        "metadata": {"friend_code": "SW-1234-5678-9012"},
        "last_synced_at": None,
        "supports_login": False,
        "supports_refresh": False,
        "supports_direct_profile_link": False,
        "supports_manual_entry": True,
        "supports_copy_only_action": True,
        "is_social_identity": True,
    }


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

    with (
        patch(
            "app.api.v1.users.service.validate_steam_login",
            new_callable=AsyncMock,
            return_value="76561198000000002",
        ),
        patch(
            "app.api.v1.users.service.get_steam_profile",
            new_callable=AsyncMock,
            return_value={
                "display_name": "Steam Relink",
                "avatar_url": "https://steamcdn.test/relink.jpg",
                "profile_url": "https://steamcommunity.com/profiles/76561198000000002",
            },
        ),
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
