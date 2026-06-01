from fastapi import HTTPException, status

from app.core.error_codes import ErrorCode


class AppHTTPException(HTTPException):
    def __init__(
        self,
        *,
        status_code: int,
        detail: str,
        code: ErrorCode,
        headers: dict[str, str] | None = None,
    ):
        super().__init__(status_code=status_code, detail=detail, headers=headers)
        self.code = code


class NotFoundError(AppHTTPException):
    def __init__(
        self,
        detail: str = "Resource not found",
        code: ErrorCode = ErrorCode.GROUP_NOT_FOUND,
    ):
        super().__init__(status_code=status.HTTP_404_NOT_FOUND, detail=detail, code=code)


class UnauthorizedError(AppHTTPException):
    def __init__(
        self,
        detail: str = "Unauthorized",
        code: ErrorCode = ErrorCode.AUTH_ACCESS_TOKEN_INVALID,
    ):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            code=code,
            headers={"WWW-Authenticate": "Bearer"},
        )


class ConflictError(AppHTTPException):
    def __init__(
        self,
        detail: str = "Resource already exists",
        code: ErrorCode = ErrorCode.GROUP_MEMBER_ALREADY_EXISTS,
    ):
        super().__init__(status_code=status.HTTP_409_CONFLICT, detail=detail, code=code)


class ValidationError(AppHTTPException):
    def __init__(
        self,
        detail: str = "Validation error",
        code: ErrorCode = ErrorCode.AUTH_STEAM_OPENID_INVALID,
    ):
        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail=detail,
            code=code,
        )


class ForbiddenError(AppHTTPException):
    def __init__(
        self,
        detail: str = "Forbidden",
        code: ErrorCode = ErrorCode.GROUP_ADMIN_OR_OWNER_REQUIRED,
    ):
        super().__init__(status_code=status.HTTP_403_FORBIDDEN, detail=detail, code=code)
