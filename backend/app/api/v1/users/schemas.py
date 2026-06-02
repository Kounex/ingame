from pydantic import BaseModel, EmailStr, Field

from app.api.v1.schemas import UserResponse

__all__ = [
    "UserResponse",
    "UpdateUserRequest",
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


class LinkSteamRequest(BaseModel):
    openid_params: dict


class LinkAppleRequest(BaseModel):
    identity_token: str


class SetEmailPasswordRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
