import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.groups import service
from app.api.v1.groups.schemas import (
    CreateGroupRequest,
    GroupMemberResponse,
    GroupResponse,
    UpdateGroupRequest,
)
from app.auth.dependencies import get_current_user
from app.db.database import get_db
from app.db.models.user import User

router = APIRouter(prefix="/groups", tags=["groups"])


@router.get("", response_model=list[GroupResponse])
async def list_groups(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_user_groups(db, current_user)


@router.post("", response_model=GroupResponse, status_code=201)
async def create_group(
    data: CreateGroupRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.create_group(
        db,
        current_user,
        name=data.name,
        description=data.description,
        is_discoverable=data.is_discoverable,
        join_mode=data.join_mode,
        avatar_url=data.avatar_url,
    )


@router.get("/discover", response_model=list[GroupResponse])
async def discover_groups(
    search: str | None = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_discoverable_groups(db, current_user.id, search)


@router.get("/join/{code}", response_model=GroupResponse)
async def preview_group_by_invite_code(
    code: str,
    _: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.preview_group_by_invite_code(db, code)


@router.get("/{group_id}", response_model=GroupResponse)
async def get_group(
    group_id: uuid.UUID,
    _: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.get_group(db, group_id)


@router.patch("/{group_id}", response_model=GroupResponse)
async def update_group(
    group_id: uuid.UUID,
    data: UpdateGroupRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.update_group(
        db,
        group_id,
        current_user,
        name=data.name,
        description=data.description,
        is_discoverable=data.is_discoverable,
        join_mode=data.join_mode,
        avatar_url=data.avatar_url,
    )


@router.delete("/{group_id}", status_code=204)
async def delete_group(
    group_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await service.delete_group(db, group_id, current_user)


@router.get("/{group_id}/members", response_model=list[GroupMemberResponse])
async def list_members(
    group_id: uuid.UUID,
    _: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_members(db, group_id)


@router.post("/join/{code}", response_model=GroupResponse)
async def join_by_invite_code(
    code: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.join_by_invite_code(db, code, current_user)


@router.delete("/{group_id}/members/{user_id}", status_code=204)
async def remove_member(
    group_id: uuid.UUID,
    user_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await service.remove_member(db, group_id, current_user, user_id)
