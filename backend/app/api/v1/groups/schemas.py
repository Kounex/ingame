import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class GroupResponse(BaseModel):
    id: uuid.UUID
    name: str
    description: str | None = None
    invite_code: str
    is_discoverable: bool
    join_mode: str
    avatar_url: str | None = None
    created_by: uuid.UUID
    created_at: datetime
    updated_at: datetime | None = None
    member_count: int = 0
    has_pending_join_request: bool = False

    model_config = {"from_attributes": True}


class CreateGroupRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    description: str | None = None
    is_discoverable: bool = False
    join_mode: str = Field(default="open", pattern="^(open|approval)$")
    avatar_url: str | None = None


class UpdateGroupRequest(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=100)
    description: str | None = None
    is_discoverable: bool | None = None
    join_mode: str | None = Field(None, pattern="^(open|approval)$")
    avatar_url: str | None = None


class GroupMemberResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    display_name: str
    avatar_url: str | None = None
    role: str
    joined_at: datetime


class AddMemberRequest(BaseModel):
    user_id: uuid.UUID
    role: str = Field(default="member", pattern="^(admin|member)$")


class UpdateMemberRoleRequest(BaseModel):
    role: str = Field(pattern="^(admin|member)$")


class TransferOwnershipRequest(BaseModel):
    user_id: uuid.UUID
