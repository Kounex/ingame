import uuid
from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.group import Group, GroupMembership, JoinRequest


class GroupRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_by_id(self, group_id: uuid.UUID) -> Group | None:
        result = await self.session.execute(select(Group).where(Group.id == group_id))
        return result.scalar_one_or_none()

    async def get_by_invite_code(self, invite_code: str) -> Group | None:
        result = await self.session.execute(
            select(Group).where(Group.invite_code == invite_code)
        )
        return result.scalar_one_or_none()

    async def list_user_groups(self, user_id: uuid.UUID) -> list[Group]:
        result = await self.session.execute(
            select(Group)
            .join(GroupMembership, GroupMembership.group_id == Group.id)
            .where(GroupMembership.user_id == user_id)
        )
        return list(result.scalars().all())

    async def list_discoverable(
        self, search: str | None = None, exclude_user_id: uuid.UUID | None = None
    ) -> list[Group]:
        query = select(Group).where(Group.is_discoverable.is_(True))
        if exclude_user_id is not None:
            member_group_ids = (
                select(GroupMembership.group_id)
                .where(GroupMembership.user_id == exclude_user_id)
                .correlate(None)
                .scalar_subquery()
            )
            query = query.where(Group.id.notin_(member_group_ids))
        if search:
            escaped = search.replace("%", "\\%").replace("_", "\\_")
            query = query.where(Group.name.ilike(f"%{escaped}%", escape="\\"))
        result = await self.session.execute(query)
        return list(result.scalars().all())

    async def create(self, **kwargs) -> Group:
        group = Group(**kwargs)
        self.session.add(group)
        await self.session.flush()
        await self.session.refresh(group)
        return group

    async def update(self, group_id: uuid.UUID, **kwargs) -> Group | None:
        group = await self.get_by_id(group_id)
        if group is None:
            return None
        for key, value in kwargs.items():
            if value is not None:
                setattr(group, key, value)
        await self.session.flush()
        await self.session.refresh(group)
        return group

    async def delete(self, group_id: uuid.UUID) -> bool:
        group = await self.get_by_id(group_id)
        if group is None:
            return False
        await self.session.delete(group)
        await self.session.flush()
        return True

    async def get_member_count(self, group_id: uuid.UUID) -> int:
        result = await self.session.execute(
            select(func.count())
            .select_from(GroupMembership)
            .where(GroupMembership.group_id == group_id)
        )
        return result.scalar_one()

    async def add_member(
        self, group_id: uuid.UUID, user_id: uuid.UUID, role: str = "member"
    ) -> GroupMembership:
        membership = GroupMembership(group_id=group_id, user_id=user_id, role=role)
        self.session.add(membership)
        await self.session.flush()
        await self.session.refresh(membership)
        return membership

    async def remove_member(
        self, group_id: uuid.UUID, user_id: uuid.UUID
    ) -> bool:
        result = await self.session.execute(
            select(GroupMembership).where(
                GroupMembership.group_id == group_id,
                GroupMembership.user_id == user_id,
            )
        )
        membership = result.scalar_one_or_none()
        if membership is None:
            return False
        await self.session.delete(membership)
        await self.session.flush()
        return True

    async def get_membership(
        self, group_id: uuid.UUID, user_id: uuid.UUID
    ) -> GroupMembership | None:
        result = await self.session.execute(
            select(GroupMembership).where(
                GroupMembership.group_id == group_id,
                GroupMembership.user_id == user_id,
            )
        )
        return result.scalar_one_or_none()

    async def update_membership_role(
        self, group_id: uuid.UUID, user_id: uuid.UUID, role: str
    ) -> GroupMembership | None:
        membership = await self.get_membership(group_id, user_id)
        if membership is None:
            return None
        membership.role = role
        await self.session.flush()
        await self.session.refresh(membership)
        return membership

    async def transfer_ownership(
        self, group_id: uuid.UUID, current_owner_id: uuid.UUID, new_owner_id: uuid.UUID
    ) -> tuple[GroupMembership, GroupMembership] | None:
        current_owner = await self.get_membership(group_id, current_owner_id)
        new_owner = await self.get_membership(group_id, new_owner_id)
        if current_owner is None or new_owner is None:
            return None

        current_owner.role = "admin"
        new_owner.role = "owner"
        await self.session.flush()
        await self.session.refresh(current_owner)
        await self.session.refresh(new_owner)
        return current_owner, new_owner

    async def list_members(self, group_id: uuid.UUID) -> list[GroupMembership]:
        result = await self.session.execute(
            select(GroupMembership).where(GroupMembership.group_id == group_id)
        )
        return list(result.scalars().all())

    async def create_join_request(
        self, group_id: uuid.UUID, user_id: uuid.UUID
    ) -> JoinRequest:
        join_request = JoinRequest(group_id=group_id, user_id=user_id)
        self.session.add(join_request)
        await self.session.flush()
        await self.session.refresh(join_request)
        return join_request

    async def get_join_request(self, request_id: uuid.UUID) -> JoinRequest | None:
        result = await self.session.execute(
            select(JoinRequest).where(JoinRequest.id == request_id)
        )
        return result.scalar_one_or_none()

    async def list_pending_requests(self, group_id: uuid.UUID) -> list[JoinRequest]:
        result = await self.session.execute(
            select(JoinRequest).where(
                JoinRequest.group_id == group_id,
                JoinRequest.status == "pending",
            )
        )
        return list(result.scalars().all())

    async def has_pending_request(
        self, group_id: uuid.UUID, user_id: uuid.UUID
    ) -> bool:
        result = await self.session.execute(
            select(func.count())
            .select_from(JoinRequest)
            .where(
                JoinRequest.group_id == group_id,
                JoinRequest.user_id == user_id,
                JoinRequest.status == "pending",
            )
        )
        return result.scalar_one() > 0

    async def resolve_join_request(
        self,
        request_id: uuid.UUID,
        status: str,
        resolved_by: uuid.UUID,
    ) -> JoinRequest | None:
        join_request = await self.get_join_request(request_id)
        if join_request is None:
            return None
        join_request.status = status
        join_request.resolved_by = resolved_by
        join_request.resolved_at = datetime.now(timezone.utc)
        await self.session.flush()
        await self.session.refresh(join_request)
        return join_request
