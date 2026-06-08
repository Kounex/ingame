import logging
import uuid
from datetime import datetime, timezone
from functools import partial
from typing import Awaitable, Callable

from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.coordination.schemas import (
    ActivityEventResponse,
    ScheduledReadyWindowResponse,
    SessionResponse,
    SessionRsvpResponse,
)
from app.core.error_codes import ErrorCode
from app.core.exceptions import ForbiddenError, NotFoundError
from app.db.models.user import User
from app.db.repositories.coordination_repo import CoordinationRepository
from app.db.repositories.group_repo import GroupRepository
from app.db.repositories.user_repo import UserRepository
from app.ws.manager import manager

_SESSION_STATUSES = {"proposed", "confirmed", "cancelled"}
AfterCommitHook = Callable[[], Awaitable[None]]
logger = logging.getLogger(__name__)


async def list_scheduled_ready_windows(
    db: AsyncSession, group_id: uuid.UUID, user: User
) -> list[ScheduledReadyWindowResponse]:
    group_repo = GroupRepository(db)
    await _ensure_member(group_repo, group_id, user.id)
    repo = CoordinationRepository(db)
    user_repo = UserRepository(db)
    windows = await repo.list_scheduled_ready_windows(group_id)
    return [await _window_to_response(window, user_repo) for window in windows]


async def create_scheduled_ready_window(
    db: AsyncSession,
    group_id: uuid.UUID,
    user: User,
    *,
    starts_at: datetime,
    ends_at: datetime,
) -> tuple[ScheduledReadyWindowResponse, tuple[AfterCommitHook, ...]]:
    _ensure_valid_range(
        starts_at,
        ends_at,
        code=ErrorCode.COORDINATION_WINDOW_TIME_INVALID,
        message="Scheduled ready windows must end after they start",
    )
    _ensure_valid_future(
        starts_at,
        code=ErrorCode.COORDINATION_WINDOW_TIME_INVALID,
        message="Scheduled ready windows must start in the future",
    )
    group_repo = GroupRepository(db)
    await _ensure_member(group_repo, group_id, user.id)
    repo = CoordinationRepository(db)
    user_repo = UserRepository(db)
    window = await repo.create_scheduled_ready_window(
        group_id=group_id,
        user_id=user.id,
        starts_at=starts_at,
        ends_at=ends_at,
        source="manual",
    )
    activity = await _record_activity(
        repo,
        actor=user,
        group_id=group_id,
        activity_type="scheduled_ready_updated",
        message=f"{user.display_name} updated their ready window",
        scheduled_ready_window_id=window.id,
    )
    response = await _window_to_response(window, user_repo)
    activity_response = await _activity_to_response(activity, user_repo)
    return response, (
        partial(
            manager.publish_scheduled_ready_updated,
            response.model_dump(mode="json"),
        ),
        partial(
            manager.publish_activity_recorded,
            activity_response.model_dump(mode="json"),
        ),
    )


async def update_scheduled_ready_window(
    db: AsyncSession,
    group_id: uuid.UUID,
    window_id: uuid.UUID,
    user: User,
    *,
    starts_at: datetime | None = None,
    ends_at: datetime | None = None,
) -> tuple[ScheduledReadyWindowResponse, tuple[AfterCommitHook, ...]]:
    group_repo = GroupRepository(db)
    await _ensure_member(group_repo, group_id, user.id)
    repo = CoordinationRepository(db)
    window = await repo.get_scheduled_ready_window(window_id)
    if window is None or window.group_id != group_id:
        raise NotFoundError(
            "Scheduled ready window not found",
            code=ErrorCode.COORDINATION_WINDOW_NOT_FOUND,
        )
    await _ensure_window_editor(group_repo, window, user.id)
    next_starts_at = starts_at or window.starts_at
    next_ends_at = ends_at or window.ends_at
    _ensure_valid_range(
        next_starts_at,
        next_ends_at,
        code=ErrorCode.COORDINATION_WINDOW_TIME_INVALID,
        message="Scheduled ready windows must end after they start",
    )
    _ensure_valid_future(
        next_starts_at,
        code=ErrorCode.COORDINATION_WINDOW_TIME_INVALID,
        message="Scheduled ready windows must start in the future",
    )

    updated = await repo.update_scheduled_ready_window(
        window_id,
        starts_at=starts_at,
        ends_at=ends_at,
    )
    user_repo = UserRepository(db)
    activity = await _record_activity(
        repo,
        actor=user,
        group_id=group_id,
        activity_type="scheduled_ready_updated",
        message=f"{user.display_name} updated their ready window",
        scheduled_ready_window_id=updated.id,
    )
    response = await _window_to_response(updated, user_repo)
    activity_response = await _activity_to_response(activity, user_repo)
    return response, (
        partial(
            manager.publish_scheduled_ready_updated,
            response.model_dump(mode="json"),
        ),
        partial(
            manager.publish_activity_recorded,
            activity_response.model_dump(mode="json"),
        ),
    )


async def delete_scheduled_ready_window(
    db: AsyncSession,
    group_id: uuid.UUID,
    window_id: uuid.UUID,
    user: User,
) -> tuple[AfterCommitHook, ...]:
    group_repo = GroupRepository(db)
    await _ensure_member(group_repo, group_id, user.id)
    repo = CoordinationRepository(db)
    window = await repo.get_scheduled_ready_window(window_id)
    if window is None or window.group_id != group_id:
        raise NotFoundError(
            "Scheduled ready window not found",
            code=ErrorCode.COORDINATION_WINDOW_NOT_FOUND,
        )
    await _ensure_window_editor(group_repo, window, user.id)
    user_repo = UserRepository(db)
    activity = await _record_activity(
        repo,
        actor=user,
        group_id=group_id,
        activity_type="scheduled_ready_deleted",
        message=f"{user.display_name} removed a ready window",
        scheduled_ready_window_id=window.id,
    )
    await repo.delete_scheduled_ready_window(window_id)
    activity_response = await _activity_to_response(activity, user_repo)
    return (
        partial(
            manager.publish_scheduled_ready_deleted,
            {
                "group_id": str(group_id),
                "window_id": str(window_id),
                "user_id": str(window.user_id),
            },
        ),
        partial(
            manager.publish_activity_recorded,
            activity_response.model_dump(mode="json"),
        ),
    )


async def list_sessions(
    db: AsyncSession,
    group_id: uuid.UUID,
    user: User,
) -> list[SessionResponse]:
    group_repo = GroupRepository(db)
    await _ensure_member(group_repo, group_id, user.id)
    repo = CoordinationRepository(db)
    user_repo = UserRepository(db)
    sessions = await repo.list_sessions(group_id)
    rsvps = await repo.list_rsvps_for_sessions([session.id for session in sessions])
    return await _sessions_to_response(sessions, rsvps, user_repo)


async def create_session(
    db: AsyncSession,
    group_id: uuid.UUID,
    user: User,
    *,
    title: str | None,
    game: str | None,
    starts_at: datetime,
    notes: str | None,
) -> tuple[SessionResponse, tuple[AfterCommitHook, ...]]:
    _ensure_valid_future(
        starts_at,
        code=ErrorCode.COORDINATION_SESSION_TIME_INVALID,
        message="Session start time must be in the future",
    )
    group_repo = GroupRepository(db)
    await _ensure_member(group_repo, group_id, user.id)
    repo = CoordinationRepository(db)
    user_repo = UserRepository(db)
    session = await repo.create_session(
        group_id=group_id,
        proposed_by=user.id,
        title=title,
        game=game,
        starts_at=starts_at,
        notes=notes,
        status="proposed",
    )
    activity = await _record_activity(
        repo,
        actor=user,
        group_id=group_id,
        activity_type="session_proposed",
        message=f"{user.display_name} proposed a session",
        session_id=session.id,
    )
    response = (await _sessions_to_response([session], [], user_repo))[0]
    activity_response = await _activity_to_response(activity, user_repo)
    return response, (
        partial(manager.publish_session_proposed, response.model_dump(mode="json")),
        partial(
            manager.publish_activity_recorded,
            activity_response.model_dump(mode="json"),
        ),
    )


async def update_session(
    db: AsyncSession,
    group_id: uuid.UUID,
    session_id: uuid.UUID,
    user: User,
    *,
    title: str | None = None,
    game: str | None = None,
    starts_at: datetime | None = None,
    notes: str | None = None,
    status: str | None = None,
) -> tuple[SessionResponse, tuple[AfterCommitHook, ...]]:
    group_repo = GroupRepository(db)
    await _ensure_member(group_repo, group_id, user.id)
    repo = CoordinationRepository(db)
    session = await repo.get_session(session_id)
    if session is None or session.group_id != group_id:
        raise NotFoundError(
            "Session not found",
            code=ErrorCode.COORDINATION_SESSION_NOT_FOUND,
        )
    await _ensure_session_editor(group_repo, session, user.id)
    if starts_at is not None:
        _ensure_valid_future(
            starts_at,
            code=ErrorCode.COORDINATION_SESSION_TIME_INVALID,
            message="Session start time must be in the future",
        )
    if status is not None and status not in _SESSION_STATUSES:
        raise ForbiddenError(
            "Invalid session status",
            code=ErrorCode.COORDINATION_SESSION_STATUS_INVALID,
        )

    updated = await repo.update_session(
        session_id,
        title=title,
        game=game,
        starts_at=starts_at,
        notes=notes,
        status=status,
    )
    user_repo = UserRepository(db)
    rsvps = await repo.list_rsvps_for_session(updated.id)
    activity = await _record_activity(
        repo,
        actor=user,
        group_id=group_id,
        activity_type="session_updated",
        message=f"{user.display_name} updated a session",
        session_id=updated.id,
    )
    response = (await _sessions_to_response([updated], rsvps, user_repo))[0]
    activity_response = await _activity_to_response(activity, user_repo)
    return response, (
        partial(manager.publish_session_updated, response.model_dump(mode="json")),
        partial(
            manager.publish_activity_recorded,
            activity_response.model_dump(mode="json"),
        ),
    )


async def delete_session(
    db: AsyncSession,
    group_id: uuid.UUID,
    session_id: uuid.UUID,
    user: User,
) -> tuple[AfterCommitHook, ...]:
    group_repo = GroupRepository(db)
    await _ensure_member(group_repo, group_id, user.id)
    repo = CoordinationRepository(db)
    session = await repo.get_session(session_id)
    if session is None or session.group_id != group_id:
        raise NotFoundError(
            "Session not found",
            code=ErrorCode.COORDINATION_SESSION_NOT_FOUND,
        )
    await _ensure_session_editor(group_repo, session, user.id)
    user_repo = UserRepository(db)
    activity = await _record_activity(
        repo,
        actor=user,
        group_id=group_id,
        activity_type="session_deleted",
        message=f"{user.display_name} removed a session",
        session_id=session.id,
    )
    await repo.delete_session(session_id)
    activity_response = await _activity_to_response(activity, user_repo)
    return (
        partial(
            manager.publish_session_deleted,
            {
                "group_id": str(group_id),
                "session_id": str(session_id),
            },
        ),
        partial(
            manager.publish_activity_recorded,
            activity_response.model_dump(mode="json"),
        ),
    )


async def upsert_rsvp(
    db: AsyncSession,
    group_id: uuid.UUID,
    session_id: uuid.UUID,
    user: User,
    *,
    response: str,
) -> tuple[SessionRsvpResponse, tuple[AfterCommitHook, ...]]:
    if response not in {"in", "out", "maybe"}:
        raise ForbiddenError(
            "Invalid RSVP response",
            code=ErrorCode.COORDINATION_RSVP_INVALID,
        )
    group_repo = GroupRepository(db)
    await _ensure_member(group_repo, group_id, user.id)
    repo = CoordinationRepository(db)
    session = await repo.get_session(session_id)
    if session is None or session.group_id != group_id:
        raise NotFoundError(
            "Session not found",
            code=ErrorCode.COORDINATION_SESSION_NOT_FOUND,
        )
    user_repo = UserRepository(db)
    rsvp = await repo.upsert_rsvp(session_id, user.id, response)
    activity = await _record_activity(
        repo,
        actor=user,
        group_id=group_id,
        activity_type="session_rsvp_updated",
        message=f"{user.display_name} responded {response} to a session",
        session_id=session.id,
    )
    response_model = await _rsvp_to_response(rsvp, user_repo)
    activity_response = await _activity_to_response(activity, user_repo)
    return response_model, (
        partial(
            manager.publish_session_rsvp_updated,
            str(group_id),
            response_model.model_dump(mode="json"),
        ),
        partial(
            manager.publish_activity_recorded,
            activity_response.model_dump(mode="json"),
        ),
    )


async def list_activity_events(
    db: AsyncSession, group_id: uuid.UUID, user: User
) -> list[ActivityEventResponse]:
    group_repo = GroupRepository(db)
    await _ensure_member(group_repo, group_id, user.id)
    repo = CoordinationRepository(db)
    user_repo = UserRepository(db)
    events = await repo.list_activity_events(group_id)
    return [await _activity_to_response(event, user_repo) for event in events]


async def publish_after_commit(hooks: tuple[AfterCommitHook, ...]) -> None:
    for hook in hooks:
        try:
            await hook()
        except Exception:
            logger.exception("Coordination post-commit publish failed")


async def _sessions_to_response(
    sessions,
    rsvps,
    user_repo: UserRepository,
) -> list[SessionResponse]:
    by_session_id: dict[uuid.UUID, list] = {}
    for rsvp in rsvps:
        by_session_id.setdefault(rsvp.session_id, []).append(rsvp)

    responses: list[SessionResponse] = []
    for session in sessions:
        proposer = await user_repo.get_by_id(session.proposed_by)
        session_rsvps = [
            await _rsvp_to_response(rsvp, user_repo)
            for rsvp in by_session_id.get(session.id, [])
        ]
        responses.append(
            SessionResponse(
                id=session.id,
                group_id=session.group_id,
                proposed_by=session.proposed_by,
                proposed_by_display_name=proposer.display_name if proposer else "Unknown",
                title=session.title,
                game=session.game,
                starts_at=_coerce_utc(session.starts_at),
                notes=session.notes,
                status=session.status,
                created_at=_coerce_utc(session.created_at),
                updated_at=_coerce_utc(session.updated_at),
                rsvps=session_rsvps,
            )
        )
    return responses


async def _window_to_response(window, user_repo: UserRepository) -> ScheduledReadyWindowResponse:
    actor = await user_repo.get_by_id(window.user_id)
    return ScheduledReadyWindowResponse(
        id=window.id,
        group_id=window.group_id,
        user_id=window.user_id,
        display_name=actor.display_name if actor else "Unknown",
        starts_at=_coerce_utc(window.starts_at),
        ends_at=_coerce_utc(window.ends_at),
        source=window.source,
        created_at=_coerce_utc(window.created_at),
        updated_at=_coerce_utc(window.updated_at),
    )


async def _rsvp_to_response(rsvp, user_repo: UserRepository) -> SessionRsvpResponse:
    actor = await user_repo.get_by_id(rsvp.user_id)
    return SessionRsvpResponse(
        id=rsvp.id,
        session_id=rsvp.session_id,
        user_id=rsvp.user_id,
        display_name=actor.display_name if actor else "Unknown",
        response=rsvp.response,
        updated_at=_coerce_utc(rsvp.updated_at),
    )


async def _activity_to_response(
    event,
    user_repo: UserRepository,
) -> ActivityEventResponse:
    actor = await user_repo.get_by_id(event.actor_user_id)
    return ActivityEventResponse(
        id=event.id,
        group_id=event.group_id,
        actor_user_id=event.actor_user_id,
        actor_display_name=actor.display_name if actor else "Unknown",
        type=event.type,
        message=event.message,
        session_id=event.session_id,
        scheduled_ready_window_id=event.scheduled_ready_window_id,
        created_at=_coerce_utc(event.created_at),
    )


async def _record_activity(
    repo: CoordinationRepository,
    *,
    actor: User,
    group_id: uuid.UUID,
    activity_type: str,
    message: str,
    session_id: uuid.UUID | None = None,
    scheduled_ready_window_id: uuid.UUID | None = None,
):
    return await repo.create_activity_event(
        group_id=group_id,
        actor_user_id=actor.id,
        type=activity_type,
        message=message,
        session_id=session_id,
        scheduled_ready_window_id=scheduled_ready_window_id,
    )


async def _ensure_member(
    group_repo: GroupRepository, group_id: uuid.UUID, user_id: uuid.UUID
) -> None:
    group = await group_repo.get_by_id(group_id)
    if group is None:
        raise NotFoundError("Group not found", code=ErrorCode.GROUP_NOT_FOUND)
    membership = await group_repo.get_membership(group_id, user_id)
    if membership is None:
        raise ForbiddenError(
            "Only group members can access this group",
            code=ErrorCode.GROUP_MEMBER_REQUIRED,
        )


async def _ensure_window_editor(group_repo: GroupRepository, window, user_id: uuid.UUID) -> None:
    if window.user_id == user_id:
        return
    membership = await group_repo.get_membership(window.group_id, user_id)
    if membership is None or membership.role not in {"owner", "admin"}:
        raise ForbiddenError(
            "You cannot edit another member's ready window",
            code=ErrorCode.COORDINATION_WINDOW_EDIT_FORBIDDEN,
        )


async def _ensure_session_editor(group_repo: GroupRepository, session, user_id: uuid.UUID) -> None:
    if session.proposed_by == user_id:
        return
    membership = await group_repo.get_membership(session.group_id, user_id)
    if membership is None or membership.role not in {"owner", "admin"}:
        raise ForbiddenError(
            "You cannot edit this session",
            code=ErrorCode.COORDINATION_SESSION_EDIT_FORBIDDEN,
        )


def _ensure_valid_range(
    starts_at: datetime,
    ends_at: datetime,
    *,
    code: ErrorCode,
    message: str,
) -> None:
    normalized_start = _coerce_utc(starts_at)
    normalized_end = _coerce_utc(ends_at)
    if normalized_end <= normalized_start:
        raise ForbiddenError(message, code=code)


def _ensure_valid_future(
    starts_at: datetime,
    *,
    code: ErrorCode,
    message: str,
) -> None:
    normalized_start = _coerce_utc(starts_at)
    if normalized_start <= datetime.now(timezone.utc):
        raise ForbiddenError(message, code=code)


def _coerce_utc(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)
