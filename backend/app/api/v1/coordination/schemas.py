import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class ScheduledReadyWindowResponse(BaseModel):
    id: uuid.UUID
    group_id: uuid.UUID
    user_id: uuid.UUID
    display_name: str
    starts_at: datetime
    ends_at: datetime
    source: str
    created_at: datetime
    updated_at: datetime | None = None


class ScheduledReadyWindowCreateRequest(BaseModel):
    starts_at: datetime
    ends_at: datetime


class ScheduledReadyWindowUpdateRequest(BaseModel):
    starts_at: datetime | None = None
    ends_at: datetime | None = None


class SessionRsvpResponse(BaseModel):
    id: uuid.UUID
    session_id: uuid.UUID
    user_id: uuid.UUID
    display_name: str
    response: str
    updated_at: datetime


class SessionResponse(BaseModel):
    id: uuid.UUID
    group_id: uuid.UUID
    proposed_by: uuid.UUID
    proposed_by_display_name: str
    title: str | None = None
    game: str | None = None
    starts_at: datetime
    notes: str | None = None
    status: str
    created_at: datetime
    updated_at: datetime | None = None
    rsvps: list[SessionRsvpResponse]


class SessionCreateRequest(BaseModel):
    title: str | None = Field(None, max_length=200)
    game: str | None = Field(None, max_length=200)
    starts_at: datetime
    notes: str | None = None


class SessionUpdateRequest(BaseModel):
    title: str | None = Field(None, max_length=200)
    game: str | None = Field(None, max_length=200)
    starts_at: datetime | None = None
    notes: str | None = None
    status: str | None = Field(None, pattern="^(proposed|confirmed|cancelled)$")


class SessionRsvpRequest(BaseModel):
    response: str = Field(pattern="^(in|out|maybe)$")


class ActivityEventResponse(BaseModel):
    id: uuid.UUID
    group_id: uuid.UUID
    actor_user_id: uuid.UUID
    actor_display_name: str
    type: str
    message: str
    session_id: uuid.UUID | None = None
    scheduled_ready_window_id: uuid.UUID | None = None
    created_at: datetime
