import uuid
from datetime import datetime, timezone
from enum import Enum

from pydantic import BaseModel, Field


class EventType(str, Enum):
    PRESENCE_SNAPSHOT = "presence_snapshot"
    USER_ONLINE = "user_online"
    USER_OFFLINE = "user_offline"
    CONNECTION_CHANGED = "connection_changed"
    READY_CHANGED = "ready_changed"
    SCHEDULED_READY_UPDATED = "scheduled_ready_updated"
    SCHEDULED_READY_DELETED = "scheduled_ready_deleted"
    SESSION_PROPOSED = "session_proposed"
    SESSION_UPDATED = "session_updated"
    SESSION_RSVP_UPDATED = "session_rsvp_updated"
    ACTIVITY_RECORDED = "activity_recorded"


class BaseEvent(BaseModel):
    type: EventType
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    group_id: uuid.UUID | None = None


class MemberPresence(BaseModel):
    user_id: uuid.UUID
    connection: str
    ready: bool = False
    ready_since: str | None = None
    ready_expires_at: str | None = None


class GroupPresenceSnapshot(BaseModel):
    group_id: uuid.UUID
    members: list[MemberPresence]


class PresenceSnapshotEvent(BaseEvent):
    type: EventType = EventType.PRESENCE_SNAPSHOT
    groups: list[GroupPresenceSnapshot]


class UserOnlineEvent(BaseEvent):
    type: EventType = EventType.USER_ONLINE
    user_id: uuid.UUID
    display_name: str
    connection: str = "online"


class UserOfflineEvent(BaseEvent):
    type: EventType = EventType.USER_OFFLINE
    user_id: uuid.UUID


class ConnectionChangedEvent(BaseEvent):
    type: EventType = EventType.CONNECTION_CHANGED
    user_id: uuid.UUID
    connection: str


class ReadyChangedEvent(BaseEvent):
    type: EventType = EventType.READY_CHANGED
    user_id: uuid.UUID
    ready: bool
    ready_since: str | None = None
    ready_expires_at: str | None = None


class ScheduledReadyUpdatedEvent(BaseEvent):
    type: EventType = EventType.SCHEDULED_READY_UPDATED
    window: dict


class ScheduledReadyDeletedEvent(BaseEvent):
    type: EventType = EventType.SCHEDULED_READY_DELETED
    window_id: uuid.UUID
    user_id: uuid.UUID


class SessionProposedEvent(BaseEvent):
    type: EventType = EventType.SESSION_PROPOSED
    session: dict


class SessionUpdatedEvent(BaseEvent):
    type: EventType = EventType.SESSION_UPDATED
    session: dict


class SessionRsvpUpdatedEvent(BaseEvent):
    type: EventType = EventType.SESSION_RSVP_UPDATED
    rsvp: dict


class ActivityRecordedEvent(BaseEvent):
    type: EventType = EventType.ACTIVITY_RECORDED
    activity: dict
