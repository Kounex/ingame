import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.notifications.schemas import (
    DeviceRegistrationRequest,
    DeviceRegistrationResponse,
    NotificationPreferenceResponse,
)
from app.auth.dependencies import get_current_user
from app.core.error_codes import ErrorCode
from app.core.exceptions import NotFoundError, ValidationError
from app.db.database import get_db
from app.db.models.user import User
from app.db.repositories.device_registration_repo import DeviceRegistrationRepository
from app.db.repositories.notification_preference_repo import NotificationPreferenceRepository

router = APIRouter(prefix="/users/me", tags=["notifications"])


@router.post(
    "/device-registrations",
    response_model=DeviceRegistrationResponse,
    status_code=201,
)
async def register_device(
    data: DeviceRegistrationRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if data.platform not in ("ios", "android", "web"):
        raise ValidationError(
            "Platform must be 'ios', 'android', or 'web'",
            code=ErrorCode.NOTIFICATION_INVALID_PLATFORM,
        )

    device_repo = DeviceRegistrationRepository(db)
    registration = await device_repo.upsert(
        user_id=current_user.id,
        platform=data.platform,
        token=data.token,
        device_label=data.device_label,
        app_version=data.app_version,
    )

    pref_repo = NotificationPreferenceRepository(db)
    if not await pref_repo.has_preferences(current_user.id):
        await pref_repo.seed_defaults(current_user.id)

    return registration


@router.get(
    "/device-registrations",
    response_model=list[DeviceRegistrationResponse],
)
async def list_device_registrations(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    repo = DeviceRegistrationRepository(db)
    return await repo.list_active_for_user(current_user.id)


@router.delete(
    "/device-registrations/{registration_id}",
    status_code=204,
)
async def delete_device_registration(
    registration_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    repo = DeviceRegistrationRepository(db)
    reg = await repo.get_by_id(registration_id)
    if reg is None or reg.user_id != current_user.id:
        raise NotFoundError(
            "Device registration not found",
            code=ErrorCode.NOTIFICATION_DEVICE_NOT_FOUND,
        )
    await repo.delete(registration_id)


@router.get(
    "/notification-preferences",
    response_model=list[NotificationPreferenceResponse],
)
async def list_notification_preferences(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    repo = NotificationPreferenceRepository(db)
    return await repo.list_for_user(current_user.id)
