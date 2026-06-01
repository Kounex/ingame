import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.apple import validate_apple_token
from app.auth.password import hash_password
from app.auth.steam import validate_steam_login
from app.core.error_codes import ErrorCode
from app.core.exceptions import ConflictError, NotFoundError, ValidationError
from app.db.models.user import User
from app.db.repositories.user_repo import UserRepository


def _count_auth_methods(user: User) -> int:
    count = 0
    if user.email and user.password_hash:
        count += 1
    if user.steam_id:
        count += 1
    if user.apple_id:
        count += 1
    return count


async def get_current_user_profile(user: User) -> User:
    return user


async def update_profile(db: AsyncSession, user: User, **kwargs) -> User:
    repo = UserRepository(db)
    update_data = {k: v for k, v in kwargs.items() if v is not None}
    if not update_data:
        return user
    updated = await repo.update(user.id, **update_data)
    if updated is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    return updated


async def get_user_by_id(db: AsyncSession, user_id: uuid.UUID) -> User:
    repo = UserRepository(db)
    user = await repo.get_by_id(user_id)
    if user is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    return user


async def link_steam(db: AsyncSession, user: User, openid_params: dict) -> User:
    try:
        steam_id = await validate_steam_login(openid_params)
    except ValueError as e:
        raise ValidationError(str(e), code=ErrorCode.AUTH_STEAM_OPENID_INVALID)

    repo = UserRepository(db)
    existing = await repo.get_by_steam_id(steam_id)
    if existing and existing.id != user.id:
        raise ConflictError(
            "This Steam account is already linked to another user",
            code=ErrorCode.USER_STEAM_ACCOUNT_ALREADY_LINKED,
        )

    updated = await repo.update(user.id, steam_id=steam_id)
    if updated is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    return updated


async def link_apple(db: AsyncSession, user: User, identity_token: str) -> User:
    try:
        apple_info = await validate_apple_token(identity_token)
    except ValueError as e:
        raise ValidationError(str(e), code=ErrorCode.AUTH_APPLE_TOKEN_INVALID)
    apple_id = apple_info["sub"]

    repo = UserRepository(db)
    existing = await repo.get_by_apple_id(apple_id)
    if existing and existing.id != user.id:
        raise ConflictError(
            "This Apple account is already linked to another user",
            code=ErrorCode.USER_APPLE_ACCOUNT_ALREADY_LINKED,
        )

    updated = await repo.update(user.id, apple_id=apple_id)
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
    if _count_auth_methods(user) <= 1:
        raise ValidationError(
            "Cannot remove your only login method. Add another before unlinking.",
            code=ErrorCode.USER_LAST_AUTH_METHOD_REQUIRED,
        )

    repo = UserRepository(db)
    user_record = await repo.get_by_id(user.id)
    if user_record is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    user_record.steam_id = None
    await db.flush()
    await db.refresh(user_record)
    return user_record


async def unlink_apple(db: AsyncSession, user: User) -> User:
    if _count_auth_methods(user) <= 1:
        raise ValidationError(
            "Cannot remove your only login method. Add another before unlinking.",
            code=ErrorCode.USER_LAST_AUTH_METHOD_REQUIRED,
        )

    repo = UserRepository(db)
    user_record = await repo.get_by_id(user.id)
    if user_record is None:
        raise NotFoundError("User not found", code=ErrorCode.USER_NOT_FOUND)
    user_record.apple_id = None
    await db.flush()
    await db.refresh(user_record)
    return user_record
