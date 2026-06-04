import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.users import service
from app.api.v1.users.schemas import (
    AvatarUploadInitRequest,
    AvatarUploadInitResponse,
    LinkAppleRequest,
    LinkSteamRequest,
    SetEmailPasswordRequest,
    UpdateUserRequest,
    UserResponse,
)
from app.auth.dependencies import get_current_user
from app.db.database import get_db
from app.db.models.user import User

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@router.patch("/me", response_model=UserResponse)
async def update_me(
    data: UpdateUserRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    updated = await service.update_profile(
        db, current_user, **data.model_dump(exclude_unset=True)
    )
    return updated


@router.post("/me/avatar-upload/init", response_model=AvatarUploadInitResponse)
async def init_avatar_upload(
    data: AvatarUploadInitRequest,
    current_user: User = Depends(get_current_user),
):
    return await service.init_avatar_upload(
        current_user,
        filename=data.filename,
        content_type=data.content_type,
        byte_size=data.byte_size,
    )


@router.post("/me/link-steam", response_model=UserResponse)
async def link_steam(
    data: LinkSteamRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.link_steam(db, current_user, data.openid_params)


@router.post("/me/link-apple", response_model=UserResponse)
async def link_apple(
    data: LinkAppleRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.link_apple(db, current_user, data.identity_token)


@router.delete("/me/link-steam", response_model=UserResponse)
async def unlink_steam(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.unlink_steam(db, current_user)


@router.delete("/me/link-apple", response_model=UserResponse)
async def unlink_apple(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.unlink_apple(db, current_user)


@router.post("/me/set-email-password", response_model=UserResponse)
async def set_email_password(
    data: SetEmailPasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.set_email_password(db, current_user, data.email, data.password)


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    return await service.get_user_by_id(db, user_id)
