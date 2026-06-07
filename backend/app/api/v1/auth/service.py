import httpx
import uuid
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.user_response import build_auth_response
from app.auth.apple import validate_apple_token
from app.auth.discord import (
    discord_access_expiry,
    exchange_discord_code,
    get_discord_profile,
)
from app.auth.jwt import create_access_token, create_refresh_token, decode_token
from app.auth.password import hash_password, verify_password
from app.auth.steam import get_steam_profile, validate_steam_login
from app.config import settings
from app.core.error_codes import ErrorCode
from app.core.exceptions import (
    ConflictError,
    ServiceUnavailableError,
    UnauthorizedError,
    ValidationError,
)
from app.db.repositories.provider_identity_repo import ProviderIdentityRepository
from app.db.repositories.revoked_auth_link_repo import RevokedAuthLinkRepository
from app.db.repositories.user_repo import UserRepository
from app.redis.client import redis_pool


async def _store_refresh_token(user_id: uuid.UUID, token: str) -> None:
    """Store refresh token in Redis."""
    from app.config import settings

    redis = redis_pool.client
    key = f"user:{user_id}:session"
    await redis.setex(key, settings.refresh_token_expire_days * 86400, token)


async def _seed_avatar_if_missing(
    repo: UserRepository,
    user,
    avatar_url: str | None,
):
    if user.avatar_url or not avatar_url:
        return user

    updated = await repo.update(user.id, avatar_url=avatar_url)
    return updated or user


async def register(db: AsyncSession, email: str, password: str, display_name: str):
    repo = UserRepository(db)

    existing = await repo.get_by_email(email)
    if existing:
        raise ConflictError(
            "A user with this email already exists",
            code=ErrorCode.AUTH_EMAIL_TAKEN,
        )

    user = await repo.create(
        email=email,
        password_hash=await hash_password(password),
        display_name=display_name,
    )

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)
    await _store_refresh_token(user.id, refresh_token)

    return await build_auth_response(
        db,
        access_token=access_token,
        refresh_token=refresh_token,
        user=user,
    )


async def login(db: AsyncSession, email: str, password: str):
    repo = UserRepository(db)
    user = await repo.get_by_email(email)

    if user is None or user.password_hash is None:
        raise UnauthorizedError(
            "Invalid email or password",
            code=ErrorCode.AUTH_INVALID_CREDENTIALS,
        )

    if not await verify_password(password, user.password_hash):
        raise UnauthorizedError(
            "Invalid email or password",
            code=ErrorCode.AUTH_INVALID_CREDENTIALS,
        )

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)
    await _store_refresh_token(user.id, refresh_token)

    return await build_auth_response(
        db,
        access_token=access_token,
        refresh_token=refresh_token,
        user=user,
    )


async def refresh(db: AsyncSession, refresh_token: str):
    try:
        payload = decode_token(refresh_token)
    except ValueError:
        raise UnauthorizedError(
            "Invalid or expired refresh token",
            code=ErrorCode.AUTH_REFRESH_TOKEN_INVALID,
        )

    if payload.get("type") != "refresh":
        raise UnauthorizedError(
            "Invalid token type",
            code=ErrorCode.AUTH_REFRESH_TOKEN_TYPE_INVALID,
        )

    user_id = payload["user_id"]

    redis = redis_pool.client
    stored_token = await redis.get(f"user:{user_id}:session")
    if stored_token != refresh_token:
        raise UnauthorizedError(
            "Refresh token has been revoked",
            code=ErrorCode.AUTH_REFRESH_TOKEN_REVOKED,
        )

    repo = UserRepository(db)
    user = await repo.get_by_id(user_id)
    if user is None:
        raise UnauthorizedError(
            "User not found",
            code=ErrorCode.AUTH_REFRESH_TOKEN_USER_NOT_FOUND,
        )

    new_access_token = create_access_token(user.id)
    new_refresh_token = create_refresh_token(user.id)
    await _store_refresh_token(user.id, new_refresh_token)

    return await build_auth_response(
        db,
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        user=user,
    )


async def steam_auth(db: AsyncSession, openid_params: dict):
    try:
        steam_id = await validate_steam_login(openid_params)
    except ValueError as e:
        raise ValidationError(str(e), code=ErrorCode.AUTH_STEAM_OPENID_INVALID)

    repo = UserRepository(db)
    identity_repo = ProviderIdentityRepository(db)
    revoked_repo = RevokedAuthLinkRepository(db)
    user = await repo.get_by_steam_id(steam_id)
    identity = await identity_repo.get_by_provider_external_id("steam", steam_id)
    if user is None and identity is not None:
        user = await repo.get_by_id(identity.user_id)
    revoked_link = await revoked_repo.get("steam", steam_id)

    if user is None and revoked_link is not None:
        raise ConflictError(
            "This Steam login was disconnected. Sign in with another method and relink Steam from profile.",
            code=ErrorCode.AUTH_STEAM_RELINK_REQUIRED,
        )

    try:
        profile = await get_steam_profile(steam_id)
    except (httpx.HTTPError, ValueError) as exc:
        raise ServiceUnavailableError(
            "Steam profile lookup is temporarily unavailable",
            code=ErrorCode.AUTH_STEAM_PROFILE_UNAVAILABLE,
        ) from exc

    if user is None:
        user = await repo.create(
            steam_id=steam_id,
            display_name=profile["display_name"],
            avatar_url=profile.get("avatar_url"),
        )
    else:
        if user.steam_id != steam_id:
            updated = await repo.update(user.id, steam_id=steam_id)
            if updated is not None:
                user = updated
        user = await _seed_avatar_if_missing(repo, user, profile.get("avatar_url"))

    await identity_repo.upsert(
        user_id=user.id,
        provider="steam",
        auth_mode="official_openid",
        external_id=steam_id,
        display_name=profile["display_name"],
        avatar_url=profile.get("avatar_url"),
        profile_url=profile.get("profile_url"),
        last_synced_at=datetime.now(timezone.utc),
    )

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)
    await _store_refresh_token(user.id, refresh_token)

    return await build_auth_response(
        db,
        access_token=access_token,
        refresh_token=refresh_token,
        user=user,
    )


async def discord_auth(
    db: AsyncSession,
    *,
    code: str,
    code_verifier: str,
    redirect_uri: str,
):
    if not settings.discord_client_id.strip():
        raise ServiceUnavailableError(
            "Discord auth is not configured on this backend. Set INGAME_DISCORD_CLIENT_ID and restart the API.",
            code=ErrorCode.AUTH_DISCORD_UNAVAILABLE,
        )

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
    identity = await identity_repo.get_by_provider_external_id("discord", discord_id)
    user = await repo.get_by_id(identity.user_id) if identity is not None else None
    revoked_link = await revoked_repo.get("discord", discord_id)

    if user is None and revoked_link is not None:
        raise ConflictError(
            "This Discord login was disconnected. Sign in with another method and relink Discord from profile.",
            code=ErrorCode.AUTH_DISCORD_RELINK_REQUIRED,
        )

    if user is None:
        name = str(profile["display_name"] or profile["username"] or f"Discord_{discord_id[:8]}")
        user = await repo.create(
            email=profile.get("email"),
            display_name=name,
            avatar_url=profile.get("avatar_url"),
        )
    else:
        user = await _seed_avatar_if_missing(repo, user, profile.get("avatar_url"))

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

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)
    await _store_refresh_token(user.id, refresh_token)

    return await build_auth_response(
        db,
        access_token=access_token,
        refresh_token=refresh_token,
        user=user,
    )


async def apple_auth(
    db: AsyncSession, identity_token: str, display_name: str | None = None
):
    try:
        apple_info = await validate_apple_token(identity_token)
    except ValueError as e:
        raise ValidationError(str(e), code=ErrorCode.AUTH_APPLE_TOKEN_INVALID)

    apple_id = apple_info["sub"]
    email = apple_info.get("email")

    repo = UserRepository(db)
    identity_repo = ProviderIdentityRepository(db)
    revoked_repo = RevokedAuthLinkRepository(db)
    user = await repo.get_by_apple_id(apple_id)
    identity = await identity_repo.get_by_provider_external_id("apple", apple_id)
    if user is None and identity is not None:
        user = await repo.get_by_id(identity.user_id)
    revoked_link = await revoked_repo.get("apple", apple_id)

    if user is None and revoked_link is not None:
        raise ConflictError(
            "This Apple login was disconnected. Sign in with another method and relink Apple from profile.",
            code=ErrorCode.AUTH_APPLE_RELINK_REQUIRED,
        )

    if user is None:
        name = display_name or email or f"Apple_{apple_id[:8]}"
        user = await repo.create(
            apple_id=apple_id,
            email=email,
            display_name=name,
        )

    await identity_repo.upsert(
        user_id=user.id,
        provider="apple",
        auth_mode="official_oauth",
        external_id=apple_id,
        email=email,
    )

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)
    await _store_refresh_token(user.id, refresh_token)

    return await build_auth_response(
        db,
        access_token=access_token,
        refresh_token=refresh_token,
        user=user,
    )
