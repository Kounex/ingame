import uuid
from datetime import datetime, timezone
from enum import Enum

from pydantic import BaseModel, Field


class EventType(str, Enum):
    PRESENCE_SNAPSHOT = "presence_snapshot"
    USER_ONLINE = "user_online"
    USER_OFFLINE = "user_offline"
    STATUS_CHANGED = "status_changed"


class BaseEvent(BaseModel):
    type: EventType
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    group_id: uuid.UUID | None = None


class UserPresence(BaseModel):
    user_id: uuid.UUID
    state: str
    game: str | None = None
    since: str | None = None


class GroupPresenceSnapshot(BaseModel):
    group_id: uuid.UUID
    online_user_ids: list[uuid.UUID]
    statuses: list[UserPresence]


class PresenceSnapshotEvent(BaseEvent):
    type: EventType = EventType.PRESENCE_SNAPSHOT
    groups: list[GroupPresenceSnapshot]


class UserOnlineEvent(BaseEvent):
    type: EventType = EventType.USER_ONLINE
    user_id: uuid.UUID
    display_name: str


class UserOfflineEvent(BaseEvent):
    type: EventType = EventType.USER_OFFLINE
    user_id: uuid.UUID


class StatusChangedEvent(BaseEvent):
    type: EventType = EventType.STATUS_CHANGED
    user_id: uuid.UUID
    state: str
    game: str | None = None
