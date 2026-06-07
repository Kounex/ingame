from pydantic import BaseModel, EmailStr, Field

from app.api.v1.schemas import UserResponse


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    display_name: str = Field(min_length=1, max_length=100)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class SteamAuthRequest(BaseModel):
    openid_params: dict


class AppleAuthRequest(BaseModel):
    identity_token: str
    display_name: str | None = None


class DiscordAuthRequest(BaseModel):
    code: str = Field(min_length=1, max_length=2048)
    code_verifier: str = Field(min_length=32, max_length=255)
    redirect_uri: str = Field(min_length=1, max_length=2048)


class AvailabilityRequest(BaseModel):
    value: str = Field(min_length=1, max_length=255)


class AvailabilityResponse(BaseModel):
    available: bool


class AuthResponse(BaseModel):
    access_token: str
    refresh_token: str
    user: UserResponse
