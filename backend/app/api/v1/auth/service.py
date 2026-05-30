import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.apple import validate_apple_token
from app.auth.jwt import create_access_token, create_refresh_token, decode_token
from app.auth.password import hash_password, verify_password
from app.auth.steam import get_steam_profile, validate_steam_login
from app.core.exceptions import ConflictError, UnauthorizedError, ValidationError
from app.db.repositories.user_repo import UserRepository
from app.redis.client import redis_pool


async def _store_refresh_token(user_id: uuid.UUID, token: str) -> None:
    """Store refresh token in Redis."""
    from app.config import settings

    redis = redis_pool.client
    key = f"user:{user_id}:session"
    await redis.setex(key, settings.refresh_token_expire_days * 86400, token)


async def register(db: AsyncSession, email: str, password: str, display_name: str):
    repo = UserRepository(db)

    existing = await repo.get_by_email(email)
    if existing:
        raise ConflictError("A user with this email already exists")

    user = await repo.create(
        email=email,
        password_hash=await hash_password(password),
        display_name=display_name,
    )

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)
    await _store_refresh_token(user.id, refresh_token)

    return {"access_token": access_token, "refresh_token": refresh_token, "user": user}


async def login(db: AsyncSession, email: str, password: str):
    repo = UserRepository(db)
    user = await repo.get_by_email(email)

    if user is None or user.password_hash is None:
        raise UnauthorizedError("Invalid email or password")

    if not await verify_password(password, user.password_hash):
        raise UnauthorizedError("Invalid email or password")

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)
    await _store_refresh_token(user.id, refresh_token)

    return {"access_token": access_token, "refresh_token": refresh_token, "user": user}


async def refresh(db: AsyncSession, refresh_token: str):
    try:
        payload = decode_token(refresh_token)
    except ValueError:
        raise UnauthorizedError("Invalid or expired refresh token")

    if payload.get("type") != "refresh":
        raise UnauthorizedError("Invalid token type")

    user_id = payload["user_id"]

    redis = redis_pool.client
    stored_token = await redis.get(f"user:{user_id}:session")
    if stored_token != refresh_token:
        raise UnauthorizedError("Refresh token has been revoked")

    repo = UserRepository(db)
    user = await repo.get_by_id(user_id)
    if user is None:
        raise UnauthorizedError("User not found")

    new_access_token = create_access_token(user.id)
    new_refresh_token = create_refresh_token(user.id)
    await _store_refresh_token(user.id, new_refresh_token)

    return {
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
        "user": user,
    }


async def steam_auth(db: AsyncSession, openid_params: dict):
    try:
        steam_id = await validate_steam_login(openid_params)
    except ValueError as e:
        raise ValidationError(str(e))

    repo = UserRepository(db)
    user = await repo.get_by_steam_id(steam_id)

    if user is None:
        profile = await get_steam_profile(steam_id)
        user = await repo.create(
            steam_id=steam_id,
            display_name=profile["display_name"],
            avatar_url=profile.get("avatar_url"),
        )

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)
    await _store_refresh_token(user.id, refresh_token)

    return {"access_token": access_token, "refresh_token": refresh_token, "user": user}


async def apple_auth(
    db: AsyncSession, identity_token: str, display_name: str | None = None
):
    try:
        apple_info = await validate_apple_token(identity_token)
    except ValueError as e:
        raise ValidationError(str(e))

    apple_id = apple_info["sub"]
    email = apple_info.get("email")

    repo = UserRepository(db)
    user = await repo.get_by_apple_id(apple_id)

    if user is None:
        name = display_name or email or f"Apple_{apple_id[:8]}"
        user = await repo.create(
            apple_id=apple_id,
            email=email,
            display_name=name,
        )

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)
    await _store_refresh_token(user.id, refresh_token)

    return {"access_token": access_token, "refresh_token": refresh_token, "user": user}
