from dataclasses import dataclass
import uuid
from datetime import datetime, timedelta, timezone
from urllib.parse import quote

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.user_response import sync_legacy_provider_identities
from app.auth.apple import validate_apple_token
from app.auth.discord import (
    discord_access_expiry,
    exchange_discord_code,
    get_discord_profile,
    refresh_discord_token,
)
from app.auth.password import hash_password
from app.auth.steam import get_steam_profile, validate_steam_login
from app.core.error_codes import ErrorCode
from app.core.provider_identity import MANUAL_PROVIDER_KEYS, provider_supports_login
from app.core.exceptions import (
    ConflictError,
    NotFoundError,
    ServiceUnavailableError,
    ValidationError,
)
from app.db.models.user import User
from app.db.repositories.avatar_upload_ledger_repo import AvatarUploadLedgerRepository
from app.db.repositories.provider_identity_repo import ProviderIdentityRepository
from app.db.repositories.revoked_auth_link_repo import RevokedAuthLinkRepository
from app.db.repositories.user_repo import UserRepository
from app.storage.avatar_uploads import (
    ALLOWED_AVATAR_CONTENT_TYPES,
    delete_avatar_object_by_public_url,
    generate_avatar_upload as create_presigned_avatar_upload,
    managed_avatar_object_key_from_public_url,
    sweep_user_avatar_prefix,
)


@dataclass(slots=True)
class ProfileUpdateResult:
    user: User
    avatar_url_to_cleanup: str | None = None
    should_sweep_avatar_prefix: bool = False


async def _count_auth_methods(db: AsyncSession, user: User) -> int:
    count = 0
    if user.email and user.password_hash:
        count += 1

    identity_repo = ProviderIdentityRepository(db)
    identities = await identity_repo.list_for_user(user.id)
    count += sum(1 for identity in identities if provider_supports_login(identity.provider))
    return count


async def _seed_avatar_if_missing(
    repo: UserRepository,
    user: User,
    avatar_url: str | None,
) -> User:
    if user.avatar_url or not avatar_url:
        return user

    updated = await repo.update(user.id, avatar_url=avatar_url)
    return updated or user


async def get_current_user_profile(db: AsyncSession, user: User) -> dict[str, object | None]:
    await sync_legacy_provider_identities(db, user)
    await refresh_stale_official_identities(db, user)
    from app.api.v1.user_response import build_user_response

    refreshed_user = await UserRepository(db).get_by_id(user.id)
    if refreshed_user is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    return await build_user_response(db, refreshed_user)


def _avatar_url_to_cleanup(
    previous_avatar_url: str | None,
    next_avatar_url: str | None,
) -> str | None:
    if not previous_avatar_url or previous_avatar_url == next_avatar_url:
        return None
    if managed_avatar_object_key_from_public_url(previous_avatar_url) is None:
        return None
    return previous_avatar_url


async def cleanup_previous_avatar(avatar_url: str | None) -> None:
    if not avatar_url:
        return
    delete_avatar_object_by_public_url(avatar_url)


async def cleanup_orphaned_avatar_uploads(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
) -> None:
    refreshed_user = await UserRepository(db).get_by_id(user_id)
    if refreshed_user is None:
        return

    sweep_user_avatar_prefix(refreshed_user.id, refreshed_user.avatar_url)


async def record_pending_avatar_upload(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    object_key: str,
    avatar_url: str,
) -> None:
    await AvatarUploadLedgerRepository(db).create_pending(
        user_id=user_id,
        object_key=object_key,
        avatar_url=avatar_url,
    )


async def mark_avatar_upload_committed(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    avatar_url: str,
) -> None:
    await AvatarUploadLedgerRepository(db).mark_committed(
        user_id=user_id,
        avatar_url=avatar_url,
    )


def avatar_upload_unclaimed_cutoff(now: datetime | None = None) -> datetime:
    from app.config import settings

    reference_time = now or datetime.now(timezone.utc)
    return reference_time - timedelta(hours=settings.avatar_upload_unclaimed_ttl_hours)


async def update_profile(db: AsyncSession, user: User, **kwargs) -> ProfileUpdateResult:
    repo = UserRepository(db)
    update_data = {
        key: value
        for key, value in kwargs.items()
        if value is not None or key == "avatar_url"
    }
    if not update_data:
        return ProfileUpdateResult(user=user)

    email = update_data.get("email")
    if email is not None and email != user.email:
        existing = await repo.get_by_email(email)
        if existing and existing.id != user.id:
            raise ConflictError(
                "This email is already in use by another account",
                code=ErrorCode.USER_EMAIL_TAKEN,
            )

    avatar_url_to_cleanup = None
    if "avatar_url" in update_data:
        avatar_url_to_cleanup = _avatar_url_to_cleanup(
            user.avatar_url,
            update_data["avatar_url"],
        )

    updated = await repo.update(user.id, **update_data)
    if updated is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    avatar_url = update_data.get("avatar_url")
    if isinstance(avatar_url, str) and avatar_url:
        await mark_avatar_upload_committed(
            db,
            user_id=user.id,
            avatar_url=avatar_url,
        )
    return ProfileUpdateResult(
        user=updated,
        avatar_url_to_cleanup=avatar_url_to_cleanup,
        should_sweep_avatar_prefix="avatar_url" in update_data,
    )


def generate_avatar_upload(
    filename: str, content_type: str, user: User
) -> dict[str, object]:
    if content_type not in ALLOWED_AVATAR_CONTENT_TYPES:
        raise ValidationError(
            "Avatar images must be JPEG, PNG, or WebP",
            code=ErrorCode.USER_AVATAR_CONTENT_TYPE_INVALID,
        )

    return create_presigned_avatar_upload(user_id=user.id, content_type=content_type)


async def init_avatar_upload(
    db: AsyncSession,
    user: User,
    *,
    filename: str,
    content_type: str,
    byte_size: int,
) -> dict[str, object]:
    from app.config import settings

    if byte_size > settings.avatar_upload_max_file_size_bytes:
        raise ValidationError(
            "Avatar image exceeds the maximum allowed file size",
            code=ErrorCode.USER_AVATAR_FILE_TOO_LARGE,
        )

    upload = generate_avatar_upload(filename, content_type, user)
    object_key = upload.get("object_key")
    avatar_url = upload.get("avatar_url")
    if isinstance(object_key, str) and isinstance(avatar_url, str):
        await record_pending_avatar_upload(
            db,
            user_id=user.id,
            object_key=object_key,
            avatar_url=avatar_url,
        )
    return upload


async def get_user_by_id(db: AsyncSession, user_id: uuid.UUID) -> User:
    repo = UserRepository(db)
    user = await repo.get_by_id(user_id)
    if user is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    await sync_legacy_provider_identities(db, user)
    return user


async def link_steam(db: AsyncSession, user: User, openid_params: dict) -> User:
    try:
        steam_id = await validate_steam_login(openid_params)
    except ValueError as e:
        raise ValidationError(str(e), code=ErrorCode.AUTH_STEAM_OPENID_INVALID)

    repo = UserRepository(db)
    identity_repo = ProviderIdentityRepository(db)
    revoked_repo = RevokedAuthLinkRepository(db)
    existing = await repo.get_by_steam_id(steam_id)
    existing_identity = await identity_repo.get_by_provider_external_id("steam", steam_id)
    if existing and existing.id != user.id:
        raise ConflictError(
            "This Steam account is already linked to another user",
            code=ErrorCode.USER_STEAM_ACCOUNT_ALREADY_LINKED,
        )
    if existing_identity and existing_identity.user_id != user.id:
        raise ConflictError(
            "This Steam account is already linked to another user",
            code=ErrorCode.USER_STEAM_ACCOUNT_ALREADY_LINKED,
        )

    try:
        profile = await get_steam_profile(steam_id)
    except (httpx.HTTPError, ValueError) as exc:
        raise ServiceUnavailableError(
            "Steam profile lookup is temporarily unavailable",
            code=ErrorCode.AUTH_STEAM_PROFILE_UNAVAILABLE,
        ) from exc

    updated = await repo.update(user.id, steam_id=steam_id)
    if updated is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    updated = await _seed_avatar_if_missing(repo, updated, profile.get("avatar_url"))
    await identity_repo.upsert(
        user_id=user.id,
        provider="steam",
        auth_mode="official_openid",
        external_id=steam_id,
        display_name=profile.get("display_name") or updated.display_name,
        avatar_url=profile.get("avatar_url"),
        profile_url=profile.get("profile_url"),
        last_synced_at=datetime.now(timezone.utc),
    )
    await revoked_repo.delete("steam", steam_id)
    return updated


async def link_apple(db: AsyncSession, user: User, identity_token: str) -> User:
    try:
        apple_info = await validate_apple_token(identity_token)
    except ValueError as e:
        raise ValidationError(str(e), code=ErrorCode.AUTH_APPLE_TOKEN_INVALID)
    apple_id = apple_info["sub"]

    repo = UserRepository(db)
    identity_repo = ProviderIdentityRepository(db)
    revoked_repo = RevokedAuthLinkRepository(db)
    existing = await repo.get_by_apple_id(apple_id)
    existing_identity = await identity_repo.get_by_provider_external_id("apple", apple_id)
    if existing and existing.id != user.id:
        raise ConflictError(
            "This Apple account is already linked to another user",
            code=ErrorCode.USER_APPLE_ACCOUNT_ALREADY_LINKED,
        )
    if existing_identity and existing_identity.user_id != user.id:
        raise ConflictError(
            "This Apple account is already linked to another user",
            code=ErrorCode.USER_APPLE_ACCOUNT_ALREADY_LINKED,
        )

    updated = await repo.update(user.id, apple_id=apple_id)
    if updated is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    await identity_repo.upsert(
        user_id=user.id,
        provider="apple",
        auth_mode="official_oauth",
        external_id=apple_id,
        email=apple_info.get("email"),
    )
    await revoked_repo.delete("apple", apple_id)
    return updated


async def link_discord(
    db: AsyncSession,
    user: User,
    *,
    code: str,
    code_verifier: str,
    redirect_uri: str,
) -> User:
    try:
        token_data = await exchange_discord_code(
            code,
            code_verifier=code_verifier,
            redirect_uri=redirect_uri,
        )
        profile = await get_discord_profile(str(token_data["access_token"]))
    except (httpx.HTTPError, KeyError, ValueError) as exc:
        raise ValidationError(
            "Discord OAuth verification failed",
            code=ErrorCode.AUTH_DISCORD_OAUTH_INVALID,
        ) from exc

    discord_id = str(profile["external_id"])
    repo = UserRepository(db)
    identity_repo = ProviderIdentityRepository(db)
    revoked_repo = RevokedAuthLinkRepository(db)
    existing_identity = await identity_repo.get_by_provider_external_id("discord", discord_id)
    if existing_identity and existing_identity.user_id != user.id:
        raise ConflictError(
            "This Discord account is already linked to another user",
            code=ErrorCode.USER_DISCORD_ACCOUNT_ALREADY_LINKED,
        )

    await identity_repo.upsert(
        user_id=user.id,
        provider="discord",
        auth_mode="official_oauth",
        external_id=discord_id,
        username=profile.get("username"),
        display_name=profile.get("display_name"),
        email=profile.get("email"),
        avatar_url=profile.get("avatar_url"),
        profile_url=profile.get("profile_url"),
        refresh_token=(
            str(token_data["refresh_token"])
            if token_data.get("refresh_token") is not None
            else None
        ),
        access_token_expires_at=discord_access_expiry(
            int(token_data["expires_in"]) if token_data.get("expires_in") else None
        ),
        last_synced_at=datetime.now(timezone.utc),
    )
    await revoked_repo.delete("discord", discord_id)

    updated = await _seed_avatar_if_missing(repo, user, profile.get("avatar_url"))
    if updated is None:
        updated = await repo.get_by_id(user.id)
    if updated is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    return updated


async def set_email_password(
    db: AsyncSession, user: User, email: str, password: str
) -> User:
    if user.email and user.password_hash:
        raise ConflictError(
            "This account already has email/password login",
            code=ErrorCode.USER_EMAIL_PASSWORD_ALREADY_SET,
        )

    repo = UserRepository(db)
    existing = await repo.get_by_email(email)
    if existing and existing.id != user.id:
        raise ConflictError(
            "This email is already in use by another account",
            code=ErrorCode.USER_EMAIL_TAKEN,
        )

    password_hash = await hash_password(password)
    updated = await repo.update(user.id, email=email, password_hash=password_hash)
    if updated is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    return updated


async def unlink_steam(db: AsyncSession, user: User) -> User:
    if await _count_auth_methods(db, user) <= 1:
        raise ValidationError(
            "Cannot remove your only login method. Add another before unlinking.",
            code=ErrorCode.USER_LAST_AUTH_METHOD_REQUIRED,
        )

    repo = UserRepository(db)
    identity_repo = ProviderIdentityRepository(db)
    revoked_repo = RevokedAuthLinkRepository(db)
    user_record = await repo.get_by_id(user.id)
    if user_record is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    steam_id = user_record.steam_id
    if steam_id is None:
        return user_record
    user_record.steam_id = None
    await revoked_repo.upsert(
        user_id=user_record.id,
        provider="steam",
        external_id=steam_id,
    )
    await identity_repo.delete_for_user(user_record.id, "steam")
    await db.flush()
    await db.refresh(user_record)
    return user_record


async def unlink_apple(db: AsyncSession, user: User) -> User:
    if await _count_auth_methods(db, user) <= 1:
        raise ValidationError(
            "Cannot remove your only login method. Add another before unlinking.",
            code=ErrorCode.USER_LAST_AUTH_METHOD_REQUIRED,
        )

    repo = UserRepository(db)
    identity_repo = ProviderIdentityRepository(db)
    revoked_repo = RevokedAuthLinkRepository(db)
    user_record = await repo.get_by_id(user.id)
    if user_record is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    apple_id = user_record.apple_id
    if apple_id is None:
        return user_record
    user_record.apple_id = None
    await revoked_repo.upsert(
        user_id=user_record.id,
        provider="apple",
        external_id=apple_id,
    )
    await identity_repo.delete_for_user(user_record.id, "apple")
    await db.flush()
    await db.refresh(user_record)
    return user_record


async def unlink_discord(db: AsyncSession, user: User) -> User:
    if await _count_auth_methods(db, user) <= 1:
        raise ValidationError(
            "Cannot remove your only login method. Add another before unlinking.",
            code=ErrorCode.USER_LAST_AUTH_METHOD_REQUIRED,
        )

    repo = UserRepository(db)
    identity_repo = ProviderIdentityRepository(db)
    revoked_repo = RevokedAuthLinkRepository(db)
    user_record = await repo.get_by_id(user.id)
    if user_record is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    identity = await identity_repo.get_for_user(user_record.id, "discord")
    if identity is None or identity.external_id is None:
        return user_record

    await revoked_repo.upsert(
        user_id=user_record.id,
        provider="discord",
        external_id=identity.external_id,
    )
    await identity_repo.delete_for_user(user_record.id, "discord")
    await db.flush()
    await db.refresh(user_record)
    return user_record


def _manual_identity_payload(
    provider: str,
    *,
    external_id: str | None,
    username: str | None,
    display_name: str | None,
    profile_url: str | None,
) -> dict[str, object | None]:
    if provider not in MANUAL_PROVIDER_KEYS:
        raise ValidationError(
            "Unsupported manual social identity provider",
            code=ErrorCode.USER_PROVIDER_IDENTITY_INVALID,
        )

    if provider == "xbox":
        gamertag = (username or external_id or "").strip()
        if not gamertag:
            raise ValidationError(
                "Xbox requires a gamertag",
                code=ErrorCode.USER_PROVIDER_IDENTITY_INVALID,
            )
        return {
            "external_id": gamertag,
            "username": gamertag,
            "display_name": None,
            "profile_url": f"https://account.xbox.com/en-us/profile?gamertag={quote(gamertag)}",
            "metadata": None,
        }

    if provider == "playstation":
        share_link = (profile_url or "").strip()
        if not share_link:
            raise ValidationError(
                "PlayStation requires a shared profile URL",
                code=ErrorCode.USER_PROVIDER_IDENTITY_INVALID,
            )
        online_id = username.strip() if username else None
        return {
            "external_id": None,
            "username": online_id,
            "display_name": None,
            "profile_url": share_link,
            "metadata": None,
        }

    friend_code = (external_id or "").strip()
    if not friend_code:
        raise ValidationError(
            "Nintendo requires a friend code",
            code=ErrorCode.USER_PROVIDER_IDENTITY_INVALID,
        )
    nickname = display_name.strip() if display_name else None
    return {
        "external_id": friend_code,
        "username": None,
        "display_name": nickname,
        "profile_url": None,
        "metadata": {"friend_code": friend_code},
    }


async def upsert_manual_social_identity(
    db: AsyncSession,
    user: User,
    *,
    provider: str,
    external_id: str | None,
    username: str | None,
    display_name: str | None,
    profile_url: str | None,
) -> User:
    payload = _manual_identity_payload(
        provider,
        external_id=external_id,
        username=username,
        display_name=display_name,
        profile_url=profile_url,
    )
    identity_repo = ProviderIdentityRepository(db)
    await identity_repo.upsert(
        user_id=user.id,
        provider=provider,
        auth_mode="manual_unverified",
        external_id=payload["external_id"],
        username=payload["username"],
        display_name=payload["display_name"],
        profile_url=payload["profile_url"],
        metadata=payload["metadata"],
    )
    updated = await UserRepository(db).get_by_id(user.id)
    if updated is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    return updated


async def delete_manual_social_identity(
    db: AsyncSession, user: User, provider: str
) -> User:
    if provider not in MANUAL_PROVIDER_KEYS:
        raise ValidationError(
            "Unsupported manual social identity provider",
            code=ErrorCode.USER_PROVIDER_IDENTITY_INVALID,
        )
    await ProviderIdentityRepository(db).delete_for_user(user.id, provider)
    updated = await UserRepository(db).get_by_id(user.id)
    if updated is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    return updated


async def refresh_stale_official_identities(db: AsyncSession, user: User) -> None:
    identity_repo = ProviderIdentityRepository(db)
    identities = await identity_repo.list_for_user(user.id)
    now = datetime.now(timezone.utc)
    stale_before = now.timestamp() - (24 * 60 * 60)

    for identity in identities:
        last_synced_at = identity.last_synced_at
        is_stale = (
            last_synced_at is None or last_synced_at.timestamp() < stale_before
        )
        if not is_stale:
            continue

        if identity.provider == "steam" and identity.external_id:
            profile = await get_steam_profile(identity.external_id)
            await identity_repo.upsert(
                user_id=user.id,
                provider="steam",
                auth_mode=identity.auth_mode,
                external_id=identity.external_id,
                display_name=profile.get("display_name"),
                avatar_url=profile.get("avatar_url"),
                profile_url=profile.get("profile_url"),
                last_synced_at=now,
            )
        elif (
            identity.provider == "discord"
            and identity.refresh_token
            and identity.external_id
        ):
            token_data = await refresh_discord_token(identity.refresh_token)
            profile = await get_discord_profile(str(token_data["access_token"]))
            await identity_repo.upsert(
                user_id=user.id,
                provider="discord",
                auth_mode=identity.auth_mode,
                external_id=str(profile["external_id"]),
                username=profile.get("username"),
                display_name=profile.get("display_name"),
                email=profile.get("email"),
                avatar_url=profile.get("avatar_url"),
                profile_url=profile.get("profile_url"),
                refresh_token=(
                    str(token_data["refresh_token"])
                    if token_data.get("refresh_token") is not None
                    else identity.refresh_token
                ),
                access_token_expires_at=discord_access_expiry(
                    int(token_data["expires_in"])
                    if token_data.get("expires_in")
                    else None
                ),
                last_synced_at=now,
            )
