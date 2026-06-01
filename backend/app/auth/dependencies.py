import uuid

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.jwt import decode_token
from app.core.error_codes import ErrorCode
from app.core.exceptions import UnauthorizedError
from app.db.database import get_db
from app.db.models.user import User
from app.db.repositories.user_repo import UserRepository

_bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    if credentials is None:
        raise UnauthorizedError(
            "Authentication credentials were not provided",
            code=ErrorCode.AUTH_MISSING_CREDENTIALS,
        )

    token = credentials.credentials
    try:
        payload = decode_token(token)
    except ValueError:
        raise UnauthorizedError(
            "Invalid or expired token",
            code=ErrorCode.AUTH_ACCESS_TOKEN_INVALID,
        )

    if payload.get("type") != "access":
        raise UnauthorizedError(
            "Invalid token type",
            code=ErrorCode.AUTH_ACCESS_TOKEN_TYPE_INVALID,
        )

    user_id: uuid.UUID = payload["user_id"]
    repo = UserRepository(db)
    user = await repo.get_by_id(user_id)
    if user is None:
        raise UnauthorizedError(
            "User not found",
            code=ErrorCode.AUTH_ACCESS_TOKEN_USER_NOT_FOUND,
        )
    return user
