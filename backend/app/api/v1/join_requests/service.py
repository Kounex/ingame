import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.error_codes import ErrorCode
from app.core.exceptions import ConflictError, ForbiddenError, NotFoundError
from app.db.models.user import User
from app.db.repositories.group_repo import GroupRepository
from app.db.repositories.user_repo import UserRepository


async def create_request(db: AsyncSession, group_id: uuid.UUID, user: User):
    repo = GroupRepository(db)
    group = await repo.get_by_id(group_id)
    if group is None:
        raise NotFoundError("Group not found", code=ErrorCode.GROUP_NOT_FOUND)

    if not group.is_discoverable:
        raise NotFoundError("Group not found", code=ErrorCode.GROUP_NOT_FOUND)

    return await _create_request_for_group(repo, group, user)


async def create_request_by_invite_code(db: AsyncSession, code: str, user: User):
    repo = GroupRepository(db)
    group = await repo.get_by_invite_code(code)
    if group is None:
        raise NotFoundError(
            "Invite code is invalid",
            code=ErrorCode.GROUP_INVITE_CODE_INVALID,
        )

    return await _create_request_for_group(repo, group, user)


async def _create_request_for_group(repo: GroupRepository, group, user: User):
    if group.join_mode != "approval":
        raise ConflictError(
            "This group does not require join requests",
            code=ErrorCode.JOIN_REQUEST_NOT_REQUIRED,
        )

    existing_membership = await repo.get_membership(group.id, user.id)
    if existing_membership:
        raise ConflictError(
            "Already a member of this group",
            code=ErrorCode.GROUP_MEMBER_ALREADY_EXISTS,
        )

    pending = await repo.list_pending_requests(group.id)
    for req in pending:
        if req.user_id == user.id:
            raise ConflictError(
                "You already have a pending request for this group",
                code=ErrorCode.JOIN_REQUEST_PENDING_ALREADY_EXISTS,
            )

    join_request = await repo.create_join_request(group.id, user.id)

    return {
        "id": join_request.id,
        "user": {
            "id": user.id,
            "display_name": user.display_name,
            "avatar_url": user.avatar_url,
        },
        "group_id": join_request.group_id,
        "status": join_request.status,
        "created_at": join_request.created_at,
        "resolved_by": join_request.resolved_by,
        "resolved_at": join_request.resolved_at,
    }


async def list_pending_for_group(
    db: AsyncSession, group_id: uuid.UUID, user: User
):
    repo = GroupRepository(db)
    user_repo = UserRepository(db)

    membership = await repo.get_membership(group_id, user.id)
    if membership is None or membership.role not in ("owner", "admin"):
        raise ForbiddenError(
            "Only admins/owners can view join requests",
            code=ErrorCode.JOIN_REQUEST_ADMIN_OR_OWNER_REQUIRED,
        )

    requests = await repo.list_pending_requests(group_id)
    results = []
    for req in requests:
        requester = await user_repo.get_by_id(req.user_id)
        results.append({
            "id": req.id,
            "user": {
                "id": req.user_id,
                "display_name": requester.display_name if requester else "Unknown",
                "avatar_url": requester.avatar_url if requester else None,
            },
            "group_id": req.group_id,
            "status": req.status,
            "created_at": req.created_at,
            "resolved_by": req.resolved_by,
            "resolved_at": req.resolved_at,
        })
    return results


async def resolve_request(
    db: AsyncSession, request_id: uuid.UUID, status: str, user: User
):
    repo = GroupRepository(db)
    user_repo = UserRepository(db)

    join_request = await repo.get_join_request(request_id)
    if join_request is None:
        raise NotFoundError(
            "Join request not found",
            code=ErrorCode.JOIN_REQUEST_NOT_FOUND,
        )

    membership = await repo.get_membership(join_request.group_id, user.id)
    if membership is None or membership.role not in ("owner", "admin"):
        raise ForbiddenError(
            "Only admins/owners can resolve join requests",
            code=ErrorCode.JOIN_REQUEST_ADMIN_OR_OWNER_REQUIRED,
        )

    if join_request.status != "pending":
        raise ConflictError(
            "Join request has already been resolved",
            code=ErrorCode.JOIN_REQUEST_ALREADY_RESOLVED,
        )

    requester_membership = await repo.get_membership(
        join_request.group_id, join_request.user_id
    )
    if status == "approved" and requester_membership is not None:
        raise ConflictError(
            "Already a member of this group",
            code=ErrorCode.GROUP_MEMBER_ALREADY_EXISTS,
        )

    resolved = await repo.resolve_join_request(request_id, status, user.id)

    if status == "approved":
        await repo.add_member(join_request.group_id, join_request.user_id, role="member")

    requester = await user_repo.get_by_id(resolved.user_id)
    return {
        "id": resolved.id,
        "user": {
            "id": resolved.user_id,
            "display_name": requester.display_name if requester else "Unknown",
            "avatar_url": requester.avatar_url if requester else None,
        },
        "group_id": resolved.group_id,
        "status": resolved.status,
        "created_at": resolved.created_at,
        "resolved_by": resolved.resolved_by,
        "resolved_at": resolved.resolved_at,
    }
