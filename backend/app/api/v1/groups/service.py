import asyncio
import secrets
import string
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.error_codes import ErrorCode
from app.core.exceptions import ConflictError, ForbiddenError, NotFoundError, ValidationError
from app.db.models.user import User
from app.db.repositories.avatar_upload_ledger_repo import AvatarUploadLedgerRepository
from app.db.repositories.group_repo import GroupRepository
from app.db.repositories.user_repo import UserRepository
from app.storage.avatar_uploads import (
    ALLOWED_AVATAR_CONTENT_TYPES,
    delete_avatar_object_by_public_url,
    generate_group_avatar_upload as create_presigned_group_avatar_upload,
    managed_avatar_object_key_from_public_url,
    sweep_group_avatar_prefix,
)
from app.ws.manager import manager as ws_manager


def _generate_invite_code(length: int = 6) -> str:
    alphabet = string.ascii_uppercase + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


async def create_group(
    db: AsyncSession,
    user: User,
    name: str,
    description: str | None,
    is_discoverable: bool,
    join_mode: str,
    avatar_url: str | None,
):
    repo = GroupRepository(db)

    invite_code = None
    for _ in range(5):
        candidate = _generate_invite_code()
        if not await repo.get_by_invite_code(candidate):
            invite_code = candidate
            break
    if invite_code is None:
        raise ConflictError(
            "Failed to generate unique invite code, please try again",
            code=ErrorCode.GROUP_INVITE_CODE_GENERATION_FAILED,
        )

    group = await repo.create(
        name=name,
        description=description,
        invite_code=invite_code,
        is_discoverable=is_discoverable,
        join_mode=join_mode,
        avatar_url=avatar_url,
        created_by=user.id,
    )

    await repo.add_member(group.id, user.id, role="owner")
    member_count = 1

    return {**_group_to_dict(group), "member_count": member_count}


async def get_group(db: AsyncSession, group_id: uuid.UUID, user: User):
    repo = GroupRepository(db)
    await _ensure_member(repo, group_id, user.id)
    group = await repo.get_by_id(group_id)
    member_count = await repo.get_member_count(group_id)
    return {**_group_to_dict(group), "member_count": member_count}


async def list_user_groups(db: AsyncSession, user: User):
    repo = GroupRepository(db)
    groups = await repo.list_user_groups(user.id)
    results = []
    for g in groups:
        count = await repo.get_member_count(g.id)
        results.append({**_group_to_dict(g), "member_count": count})
    return results


async def list_discoverable_groups(
    db: AsyncSession, user_id: uuid.UUID, search: str | None = None
):
    repo = GroupRepository(db)
    groups = await repo.list_discoverable(search, exclude_user_id=user_id)
    results = []
    for g in groups:
        count = await repo.get_member_count(g.id)
        pending = await repo.has_pending_request(g.id, user_id)
        results.append(
            {
                **_group_to_dict(g, has_pending_join_request=pending),
                "member_count": count,
            }
        )
    return results


async def update_group(
    db: AsyncSession, group_id: uuid.UUID, user: User, **kwargs
):
    repo = GroupRepository(db)
    owner_only_fields = {"is_discoverable", "join_mode"}
    if any(f in kwargs for f in owner_only_fields):
        await _ensure_owner(repo, group_id, user.id)
    else:
        await _ensure_admin_or_owner(repo, group_id, user.id)

    if not kwargs:
        group = await repo.get_by_id(group_id)
        member_count = await repo.get_member_count(group_id)
        return {**_group_to_dict(group), "member_count": member_count}, None, False

    previous_group = await repo.get_by_id(group_id)
    if previous_group is None:
        raise NotFoundError("Group not found", code=ErrorCode.GROUP_NOT_FOUND)

    avatar_url_to_cleanup = None
    should_sweep = False
    if "avatar_url" in kwargs:
        avatar_url_to_cleanup = _group_avatar_url_to_cleanup(
            previous_group.avatar_url,
            kwargs["avatar_url"],
        )
        should_sweep = True

    group = await repo.update(group_id, **kwargs)
    if group is None:
        raise NotFoundError("Group not found", code=ErrorCode.GROUP_NOT_FOUND)

    avatar_url = kwargs.get("avatar_url")
    if isinstance(avatar_url, str) and avatar_url:
        await AvatarUploadLedgerRepository(db).mark_committed(
            user_id=user.id,
            avatar_url=avatar_url,
        )

    member_count = await repo.get_member_count(group_id)
    result = {**_group_to_dict(group), "member_count": member_count}
    asyncio.create_task(ws_manager.publish_group_updated(str(group_id), result))
    return result, avatar_url_to_cleanup, should_sweep


async def delete_group(db: AsyncSession, group_id: uuid.UUID, user: User):
    repo = GroupRepository(db)
    await _ensure_owner(repo, group_id, user.id, code=ErrorCode.GROUP_DELETE_REQUIRES_OWNER)
    deleted = await repo.delete(group_id)
    if not deleted:
        raise NotFoundError("Group not found", code=ErrorCode.GROUP_NOT_FOUND)
    asyncio.create_task(ws_manager.publish_group_deleted(str(group_id)))
    return group_id


async def join_by_invite_code(db: AsyncSession, code: str, user: User):
    repo = GroupRepository(db)
    group = await repo.get_by_invite_code(code)
    if group is None:
        raise NotFoundError(
            "Invalid invite code",
            code=ErrorCode.GROUP_INVITE_CODE_INVALID,
        )

    existing = await repo.get_membership(group.id, user.id)
    if existing:
        raise ConflictError(
            "Already a member of this group",
            code=ErrorCode.GROUP_MEMBER_ALREADY_EXISTS,
        )

    if group.join_mode == "approval":
        raise ForbiddenError(
            "This group requires approval before joining",
            code=ErrorCode.JOIN_REQUEST_REQUIRED,
        )

    await repo.add_member(group.id, user.id, role="member")
    member_count = await repo.get_member_count(group.id)
    asyncio.create_task(ws_manager.publish_member_joined(
        str(group.id), user.id, user.display_name, user.avatar_url,
    ))
    return {**_group_to_dict(group), "member_count": member_count}


async def preview_group_by_invite_code(db: AsyncSession, code: str, user: User):
    repo = GroupRepository(db)
    group = await repo.get_by_invite_code(code)
    if group is None:
        raise NotFoundError(
            "Invalid invite code",
            code=ErrorCode.GROUP_INVITE_CODE_INVALID,
        )

    member_count = await repo.get_member_count(group.id)
    pending = await repo.has_pending_request(group.id, user.id)
    return {
        **_group_to_dict(group, has_pending_join_request=pending),
        "member_count": member_count,
    }


async def add_member(
    db: AsyncSession, group_id: uuid.UUID, user: User, target_user_id: uuid.UUID, role: str
):
    repo = GroupRepository(db)
    await _ensure_admin_or_owner(repo, group_id, user.id)

    existing = await repo.get_membership(group_id, target_user_id)
    if existing:
        raise ConflictError(
            "User is already a member",
            code=ErrorCode.GROUP_MEMBER_ALREADY_EXISTS,
        )

    await repo.add_member(group_id, target_user_id, role=role)


async def remove_member(
    db: AsyncSession, group_id: uuid.UUID, user: User, target_user_id: uuid.UUID
):
    repo = GroupRepository(db)

    if user.id != target_user_id:
        await _ensure_admin_or_owner(repo, group_id, user.id)

    target_membership = await repo.get_membership(group_id, target_user_id)
    if target_membership is None:
        raise NotFoundError(
            "User is not a member of this group",
            code=ErrorCode.GROUP_MEMBER_NOT_FOUND,
        )
    if target_membership.role == "owner":
        code = (
            ErrorCode.GROUP_OWNER_CANNOT_LEAVE
            if user.id == target_user_id
            else ErrorCode.GROUP_OWNER_CANNOT_BE_REMOVED
        )
        raise ForbiddenError(
            "The group owner must transfer ownership or delete the group first",
            code=code,
        )

    if user.id != target_user_id and target_membership.role == "admin":
        actor_membership = await repo.get_membership(group_id, user.id)
        if actor_membership and actor_membership.role != "owner":
            raise ForbiddenError(
                "Only the group owner can remove admins",
                code=ErrorCode.GROUP_OWNER_REQUIRED,
            )

    removed = await repo.remove_member(group_id, target_user_id)
    if not removed:
        raise NotFoundError("Member not found", code=ErrorCode.GROUP_MEMBER_NOT_FOUND)

    if user.id == target_user_id:
        asyncio.create_task(ws_manager.publish_member_left(str(group_id), target_user_id))
    else:
        asyncio.create_task(ws_manager.publish_member_removed(
            str(group_id), target_user_id, user.id,
        ))


async def leave_group(db: AsyncSession, group_id: uuid.UUID, user: User):
    await remove_member(db, group_id, user, user.id)


async def list_members(
    db: AsyncSession, group_id: uuid.UUID, user: User | None = None
):
    repo = GroupRepository(db)
    if user is not None:
        await _ensure_member(repo, group_id, user.id)
    else:
        group = await repo.get_by_id(group_id)
        if group is None:
            raise NotFoundError("Group not found", code=ErrorCode.GROUP_NOT_FOUND)
    user_repo = UserRepository(db)
    memberships = await repo.list_members(group_id)
    results = []
    for m in memberships:
        u = await user_repo.get_by_id(m.user_id)
        results.append({
            "id": m.id,
            "user_id": m.user_id,
            "display_name": u.display_name if u else "Unknown",
            "avatar_url": u.avatar_url if u else None,
            "role": m.role,
            "joined_at": m.joined_at,
        })
    return results


async def update_member_role(
    db: AsyncSession,
    group_id: uuid.UUID,
    user: User,
    target_user_id: uuid.UUID,
    role: str,
):
    repo = GroupRepository(db)
    await _ensure_owner(repo, group_id, user.id)

    membership = await repo.get_membership(group_id, target_user_id)
    if membership is None:
        raise NotFoundError(
            "User is not a member of this group",
            code=ErrorCode.GROUP_MEMBER_NOT_FOUND,
        )
    if membership.role == "owner":
        raise ForbiddenError(
            "Transfer ownership instead of changing the owner role directly",
            code=ErrorCode.GROUP_INVALID_ROLE_CHANGE,
        )
    if role not in ("admin", "member"):
        raise ForbiddenError(
            "Invalid group role change",
            code=ErrorCode.GROUP_INVALID_ROLE_CHANGE,
        )

    await repo.update_membership_role(group_id, target_user_id, role)
    asyncio.create_task(ws_manager.publish_member_role_changed(
        str(group_id), target_user_id, role,
    ))


async def transfer_ownership(
    db: AsyncSession,
    group_id: uuid.UUID,
    user: User,
    target_user_id: uuid.UUID,
):
    repo = GroupRepository(db)
    await _ensure_owner(repo, group_id, user.id)

    if user.id == target_user_id:
        raise ForbiddenError(
            "Choose another member to transfer ownership to",
            code=ErrorCode.GROUP_TRANSFER_INVALID_TARGET,
        )

    target_membership = await repo.get_membership(group_id, target_user_id)
    if target_membership is None:
        raise NotFoundError(
            "User is not a member of this group",
            code=ErrorCode.GROUP_MEMBER_NOT_FOUND,
        )
    if target_membership.role == "owner":
        raise ForbiddenError(
            "Target user already owns the group",
            code=ErrorCode.GROUP_TRANSFER_INVALID_TARGET,
        )

    transferred = await repo.transfer_ownership(group_id, user.id, target_user_id)
    if transferred is None:
        raise NotFoundError("Group member not found", code=ErrorCode.GROUP_MEMBER_NOT_FOUND)
    asyncio.create_task(ws_manager.publish_member_role_changed(
        str(group_id), target_user_id, "owner",
    ))
    asyncio.create_task(ws_manager.publish_member_role_changed(
        str(group_id), user.id, "admin",
    ))


async def init_group_avatar_upload(
    db: AsyncSession,
    group_id: uuid.UUID,
    user: User,
    *,
    filename: str,
    content_type: str,
    byte_size: int,
) -> dict[str, object]:
    from app.config import settings

    repo = GroupRepository(db)
    await _ensure_admin_or_owner(repo, group_id, user.id)

    if byte_size > settings.avatar_upload_max_file_size_bytes:
        raise ValidationError(
            "Avatar image exceeds the maximum allowed file size",
            code=ErrorCode.USER_AVATAR_FILE_TOO_LARGE,
        )

    if content_type not in ALLOWED_AVATAR_CONTENT_TYPES:
        raise ValidationError(
            "Avatar images must be JPEG, PNG, or WebP",
            code=ErrorCode.USER_AVATAR_CONTENT_TYPE_INVALID,
        )

    upload = create_presigned_group_avatar_upload(
        group_id=group_id, content_type=content_type,
    )
    object_key = upload.get("object_key")
    avatar_url = upload.get("avatar_url")
    if isinstance(object_key, str) and isinstance(avatar_url, str):
        await AvatarUploadLedgerRepository(db).create_pending(
            user_id=user.id,
            object_key=object_key,
            avatar_url=avatar_url,
        )
    return upload


def _group_avatar_url_to_cleanup(
    previous_avatar_url: str | None,
    next_avatar_url: str | None,
) -> str | None:
    if not previous_avatar_url or previous_avatar_url == next_avatar_url:
        return None
    if managed_avatar_object_key_from_public_url(previous_avatar_url) is None:
        return None
    return previous_avatar_url


async def _ensure_admin_or_owner(
    repo: GroupRepository, group_id: uuid.UUID, user_id: uuid.UUID
):
    membership = await repo.get_membership(group_id, user_id)
    if membership is None or membership.role not in ("owner", "admin"):
        raise ForbiddenError(
            "Only group owners or admins can perform this action",
            code=ErrorCode.GROUP_ADMIN_OR_OWNER_REQUIRED,
        )


async def _ensure_owner(
    repo: GroupRepository,
    group_id: uuid.UUID,
    user_id: uuid.UUID,
    *,
    code: ErrorCode = ErrorCode.GROUP_OWNER_REQUIRED,
):
    membership = await repo.get_membership(group_id, user_id)
    if membership is None or membership.role != "owner":
        raise ForbiddenError(
            "Only the group owner can perform this action",
            code=code,
        )


async def _ensure_member(
    repo: GroupRepository,
    group_id: uuid.UUID,
    user_id: uuid.UUID | None = None,
):
    group = await repo.get_by_id(group_id)
    if group is None:
        raise NotFoundError("Group not found", code=ErrorCode.GROUP_NOT_FOUND)
    if user_id is None:
        return group

    membership = await repo.get_membership(group_id, user_id)
    if membership is None:
        raise ForbiddenError(
            "Only group members can access this group",
            code=ErrorCode.GROUP_MEMBER_REQUIRED,
        )
    return group


def _group_to_dict(group, *, has_pending_join_request: bool = False) -> dict:
    return {
        "id": group.id,
        "name": group.name,
        "description": group.description,
        "invite_code": group.invite_code,
        "is_discoverable": group.is_discoverable,
        "join_mode": group.join_mode,
        "avatar_url": group.avatar_url,
        "created_by": group.created_by,
        "created_at": group.created_at,
        "updated_at": group.updated_at,
        "has_pending_join_request": has_pending_join_request,
    }
