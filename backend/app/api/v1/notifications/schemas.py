import uuid
from datetime import datetime, time

from pydantic import BaseModel, Field


class DeviceRegistrationRequest(BaseModel):
    platform: str = Field(pattern="^(ios|android|web)$")
    token: str = Field(min_length=1)
    device_label: str | None = Field(None, max_length=128)
    app_version: str | None = Field(None, max_length=32)


class DeviceRegistrationResponse(BaseModel):
    id: uuid.UUID
    platform: str
    token: str
    device_label: str | None = None
    last_seen_at: datetime

    model_config = {"from_attributes": True}


class NotificationPreferenceResponse(BaseModel):
    id: uuid.UUID
    scope: str
    scope_id: uuid.UUID | None = None
    event_type: str | None = None
    enabled: bool
    conditions: dict | None = None
    quiet_hours_start: time | None = None
    quiet_hours_end: time | None = None
    quiet_hours_tz: str | None = None
    updated_at: datetime

    model_config = {"from_attributes": True}
