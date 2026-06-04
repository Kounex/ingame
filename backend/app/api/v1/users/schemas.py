from pydantic import BaseModel, EmailStr, Field

from app.api.v1.schemas import UserResponse

__all__ = [
    "UserResponse",
    "UpdateUserRequest",
    "AvatarUploadInitRequest",
    "AvatarUploadInitResponse",
    "LinkSteamRequest",
    "LinkAppleRequest",
    "SetEmailPasswordRequest",
]


class UpdateUserRequest(BaseModel):
    email: EmailStr | None = None
    display_name: str | None = Field(None, min_length=1, max_length=100)
    avatar_url: str | None = None
    bio: str | None = None
    timezone: str | None = None
    preferred_gaming_hours: dict | None = None


class AvatarUploadInitRequest(BaseModel):
    filename: str = Field(min_length=1, max_length=255)
    content_type: str = Field(min_length=1, max_length=100)
    byte_size: int = Field(gt=0)


class AvatarUploadInitResponse(BaseModel):
    upload_url: str
    upload_fields: dict[str, str]
    object_key: str
    avatar_url: str
    expires_in_seconds: int
    max_file_size_bytes: int
    allowed_content_types: list[str]


class LinkSteamRequest(BaseModel):
    openid_params: dict


class LinkAppleRequest(BaseModel):
    identity_token: str


class SetEmailPasswordRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
