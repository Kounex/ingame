from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.auth import service
from app.api.v1.auth.schemas import (
    AppleAuthRequest,
    AuthResponse,
    AvailabilityRequest,
    AvailabilityResponse,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    SteamAuthRequest,
)
from app.db.database import get_db
from app.db.repositories.user_repo import UserRepository

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=AuthResponse, status_code=201)
async def register(data: RegisterRequest, db: AsyncSession = Depends(get_db)):
    result = await service.register(db, data.email, data.password, data.display_name)
    return result


@router.post("/login", response_model=AuthResponse)
async def login(data: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await service.login(db, data.email, data.password)
    return result


@router.post("/refresh", response_model=AuthResponse)
async def refresh(data: RefreshRequest, db: AsyncSession = Depends(get_db)):
    result = await service.refresh(db, data.refresh_token)
    return result


@router.post("/check-email", response_model=AvailabilityResponse)
async def check_email(data: AvailabilityRequest, db: AsyncSession = Depends(get_db)):
    repo = UserRepository(db)
    exists = await repo.email_exists(data.value)
    return {"available": not exists}


@router.post("/check-display-name", response_model=AvailabilityResponse)
async def check_display_name(
    data: AvailabilityRequest, db: AsyncSession = Depends(get_db)
):
    repo = UserRepository(db)
    exists = await repo.display_name_exists(data.value)
    return {"available": not exists}


@router.post("/steam", response_model=AuthResponse)
async def steam_auth(data: SteamAuthRequest, db: AsyncSession = Depends(get_db)):
    result = await service.steam_auth(db, data.openid_params)
    return result


@router.post("/apple", response_model=AuthResponse)
async def apple_auth(data: AppleAuthRequest, db: AsyncSession = Depends(get_db)):
    result = await service.apple_auth(db, data.identity_token, data.display_name)
    return result
