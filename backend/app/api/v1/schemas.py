import uuid
from datetime import datetime

from pydantic import BaseModel


class ProviderIdentityResponse(BaseModel):
    provider: str
    auth_mode: str
    external_id: str | None = None
    username: str | None = None
    display_name: str | None = None
    email: str | None = None
    avatar_url: str | None = None
    profile_url: str | None = None
    metadata: dict | None = None
    last_synced_at: datetime | None = None
    supports_login: bool
    supports_refresh: bool
    supports_direct_profile_link: bool
    supports_manual_entry: bool
    supports_copy_only_action: bool
    is_social_identity: bool


class UserResponse(BaseModel):
    id: uuid.UUID
    email: str | None = None
    display_name: str
    has_password_login: bool
    avatar_url: str | None = None
    bio: str | None = None
    timezone: str
    preferred_gaming_hours: dict | None = None
    steam_id: str | None = None
    apple_id: str | None = None
    provider_identities: list[ProviderIdentityResponse] = []
    created_at: datetime
    updated_at: datetime | None = None

    model_config = {"from_attributes": True}
