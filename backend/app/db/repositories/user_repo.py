import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.user import User


class UserRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_by_id(self, user_id: uuid.UUID) -> User | None:
        result = await self.session.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> User | None:
        result = await self.session.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    async def get_by_steam_id(self, steam_id: str) -> User | None:
        result = await self.session.execute(
            select(User).where(User.steam_id == steam_id)
        )
        return result.scalar_one_or_none()

    async def get_by_apple_id(self, apple_id: str) -> User | None:
        result = await self.session.execute(
            select(User).where(User.apple_id == apple_id)
        )
        return result.scalar_one_or_none()

    async def email_exists(self, email: str) -> bool:
        result = await self.session.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none() is not None

    async def display_name_exists(self, display_name: str) -> bool:
        from sqlalchemy import func

        result = await self.session.execute(
            select(User).where(func.lower(User.display_name) == display_name.lower())
        )
        return result.scalar_one_or_none() is not None

    async def create(self, **kwargs) -> User:
        user = User(**kwargs)
        self.session.add(user)
        await self.session.flush()
        await self.session.refresh(user)
        return user

    async def update(self, user_id: uuid.UUID, **kwargs) -> User | None:
        user = await self.get_by_id(user_id)
        if user is None:
            return None
        for key, value in kwargs.items():
            if value is not None:
                setattr(user, key, value)
        await self.session.flush()
        await self.session.refresh(user)
        return user
