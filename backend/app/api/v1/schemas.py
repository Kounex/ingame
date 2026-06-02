import uuid
from datetime import datetime

from pydantic import BaseModel


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
    created_at: datetime
    updated_at: datetime | None = None

    model_config = {"from_attributes": True}
