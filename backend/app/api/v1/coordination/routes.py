import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.coordination import service
from app.api.v1.coordination.schemas import (
    ActivityEventResponse,
    ScheduledReadyWindowCreateRequest,
    ScheduledReadyWindowResponse,
    ScheduledReadyWindowUpdateRequest,
    SessionCreateRequest,
    SessionResponse,
    SessionRsvpRequest,
    SessionRsvpResponse,
    SessionUpdateRequest,
)
from app.auth.dependencies import get_current_user
from app.db.database import get_db
from app.db.models.user import User

router = APIRouter(prefix="/groups", tags=["coordination"])


@router.get("/{group_id}/scheduled-ready", response_model=list[ScheduledReadyWindowResponse])
async def list_scheduled_ready(
    group_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_scheduled_ready_windows(db, group_id, current_user)


@router.post("/{group_id}/scheduled-ready", response_model=ScheduledReadyWindowResponse, status_code=201)
async def create_scheduled_ready(
    group_id: uuid.UUID,
    data: ScheduledReadyWindowCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    response, hooks = await service.create_scheduled_ready_window(
        db,
        group_id,
        current_user,
        starts_at=data.starts_at,
        ends_at=data.ends_at,
    )
    await db.commit()
    await service.publish_after_commit(hooks)
    return response


@router.patch("/{group_id}/scheduled-ready/{window_id}", response_model=ScheduledReadyWindowResponse)
async def update_scheduled_ready(
    group_id: uuid.UUID,
    window_id: uuid.UUID,
    data: ScheduledReadyWindowUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    response, hooks = await service.update_scheduled_ready_window(
        db,
        group_id,
        window_id,
        current_user,
        starts_at=data.starts_at,
        ends_at=data.ends_at,
    )
    await db.commit()
    await service.publish_after_commit(hooks)
    return response


@router.delete("/{group_id}/scheduled-ready/{window_id}", status_code=204)
async def delete_scheduled_ready(
    group_id: uuid.UUID,
    window_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    hooks = await service.delete_scheduled_ready_window(
        db, group_id, window_id, current_user
    )
    await db.commit()
    await service.publish_after_commit(hooks)


@router.get("/{group_id}/sessions", response_model=list[SessionResponse])
async def list_sessions(
    group_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_sessions(db, group_id, current_user)


@router.post("/{group_id}/sessions", response_model=SessionResponse, status_code=201)
async def create_session(
    group_id: uuid.UUID,
    data: SessionCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    response, hooks = await service.create_session(
        db,
        group_id,
        current_user,
        title=data.title,
        game=data.game,
        starts_at=data.starts_at,
        notes=data.notes,
    )
    await db.commit()
    await service.publish_after_commit(hooks)
    return response


@router.patch("/{group_id}/sessions/{session_id}", response_model=SessionResponse)
async def update_session(
    group_id: uuid.UUID,
    session_id: uuid.UUID,
    data: SessionUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    response, hooks = await service.update_session(
        db,
        group_id,
        session_id,
        current_user,
        title=data.title,
        game=data.game,
        starts_at=data.starts_at,
        notes=data.notes,
        status=data.status,
    )
    await db.commit()
    await service.publish_after_commit(hooks)
    return response


@router.post("/{group_id}/sessions/{session_id}/rsvp", response_model=SessionRsvpResponse)
async def rsvp_session(
    group_id: uuid.UUID,
    session_id: uuid.UUID,
    data: SessionRsvpRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    response, hooks = await service.upsert_rsvp(
        db,
        group_id,
        session_id,
        current_user,
        response=data.response,
    )
    await db.commit()
    await service.publish_after_commit(hooks)
    return response


@router.get("/{group_id}/activity", response_model=list[ActivityEventResponse])
async def list_activity(
    group_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_activity_events(db, group_id, current_user)
