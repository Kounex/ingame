import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class JoinRequestUserInfo(BaseModel):
    id: uuid.UUID
    display_name: str
    avatar_url: str | None = None


class JoinRequestResponse(BaseModel):
    id: uuid.UUID
    user: JoinRequestUserInfo
    group_id: uuid.UUID
    status: str
    created_at: datetime
    resolved_by: uuid.UUID | None = None
    resolved_at: datetime | None = None


class ResolveJoinRequestRequest(BaseModel):
    status: str = Field(pattern="^(approved|denied)$")
