import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.join_requests import service
from app.api.v1.join_requests.schemas import (
    JoinRequestResponse,
    ResolveJoinRequestRequest,
)
from app.auth.dependencies import get_current_user
from app.db.database import get_db
from app.db.models.user import User

router = APIRouter(tags=["join-requests"])


@router.post(
    "/groups/{group_id}/join-requests",
    response_model=JoinRequestResponse,
    status_code=201,
)
async def create_join_request(
    group_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.create_request(db, group_id, current_user)


@router.post(
    "/groups/join/{code}/requests",
    response_model=JoinRequestResponse,
    status_code=201,
)
async def create_join_request_by_invite_code(
    code: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.create_request_by_invite_code(db, code, current_user)


@router.get(
    "/groups/{group_id}/join-requests",
    response_model=list[JoinRequestResponse],
)
async def list_pending_requests(
    group_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_pending_for_group(db, group_id, current_user)


@router.patch(
    "/join-requests/{request_id}",
    response_model=JoinRequestResponse,
)
async def resolve_join_request(
    request_id: uuid.UUID,
    data: ResolveJoinRequestRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.resolve_request(db, request_id, data.status, current_user)
