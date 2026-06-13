import uuid
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.device_registration import DeviceRegistration
from app.db.repositories.device_registration_repo import DeviceRegistrationRepository


@pytest.mark.asyncio
async def test_upsert_creates_new_registration(db_session: AsyncSession):
    user_id = uuid.uuid4()
    from app.db.repositories.user_repo import UserRepository
    user_repo = UserRepository(db_session)
    await user_repo.create(id=user_id, display_name="Test User", email="test@test.com", password_hash="hash")

    repo = DeviceRegistrationRepository(db_session)
    reg = await repo.upsert(
        user_id=user_id,
        platform="ios",
        token="fcm-token-abc",
        device_label="iPhone 17",
        app_version="1.0.0",
    )
    assert reg.user_id == user_id
    assert reg.platform == "ios"
    assert reg.token == "fcm-token-abc"
    assert reg.device_label == "iPhone 17"
    assert reg.revoked_at is None


@pytest.mark.asyncio
async def test_upsert_updates_existing_registration(db_session: AsyncSession):
    user_id = uuid.uuid4()
    from app.db.repositories.user_repo import UserRepository
    user_repo = UserRepository(db_session)
    await user_repo.create(id=user_id, display_name="Test", email="t@t.com", password_hash="h")

    repo = DeviceRegistrationRepository(db_session)
    reg1 = await repo.upsert(user_id=user_id, platform="ios", token="tok1")
    original_id = reg1.id

    reg2 = await repo.upsert(
        user_id=user_id, platform="ios", token="tok1", device_label="New Label"
    )
    assert reg2.id == original_id
    assert reg2.device_label == "New Label"


@pytest.mark.asyncio
async def test_upsert_clears_revoked_at(db_session: AsyncSession):
    user_id = uuid.uuid4()
    from app.db.repositories.user_repo import UserRepository
    user_repo = UserRepository(db_session)
    await user_repo.create(id=user_id, display_name="Test", email="r@t.com", password_hash="h")

    repo = DeviceRegistrationRepository(db_session)
    reg = await repo.upsert(user_id=user_id, platform="ios", token="tok-revoke")
    await repo.revoke(reg.id)
    refreshed = await repo.get_by_id(reg.id)
    assert refreshed.revoked_at is not None

    re_registered = await repo.upsert(user_id=user_id, platform="ios", token="tok-revoke")
    assert re_registered.revoked_at is None


@pytest.mark.asyncio
async def test_list_active_for_user(db_session: AsyncSession):
    user_id = uuid.uuid4()
    from app.db.repositories.user_repo import UserRepository
    user_repo = UserRepository(db_session)
    await user_repo.create(id=user_id, display_name="Test", email="a@t.com", password_hash="h")

    repo = DeviceRegistrationRepository(db_session)
    await repo.upsert(user_id=user_id, platform="ios", token="active1")
    reg2 = await repo.upsert(user_id=user_id, platform="android", token="active2")
    await repo.revoke(reg2.id)

    active = await repo.list_active_for_user(user_id)
    assert len(active) == 1
    assert active[0].token == "active1"


@pytest.mark.asyncio
async def test_revoke(db_session: AsyncSession):
    user_id = uuid.uuid4()
    from app.db.repositories.user_repo import UserRepository
    user_repo = UserRepository(db_session)
    await user_repo.create(id=user_id, display_name="Test", email="rv@t.com", password_hash="h")

    repo = DeviceRegistrationRepository(db_session)
    reg = await repo.upsert(user_id=user_id, platform="ios", token="tok-rv")
    assert await repo.revoke(reg.id) is True
    refreshed = await repo.get_by_id(reg.id)
    assert refreshed.revoked_at is not None


@pytest.mark.asyncio
async def test_revoke_by_token(db_session: AsyncSession):
    user_id = uuid.uuid4()
    from app.db.repositories.user_repo import UserRepository
    user_repo = UserRepository(db_session)
    await user_repo.create(id=user_id, display_name="Test", email="rvt@t.com", password_hash="h")

    repo = DeviceRegistrationRepository(db_session)
    await repo.upsert(user_id=user_id, platform="ios", token="tok-rvt")
    assert await repo.revoke_by_token(user_id, "tok-rvt") is True
    active = await repo.list_active_for_user(user_id)
    assert len(active) == 0


@pytest.mark.asyncio
async def test_list_stale(db_session: AsyncSession):
    user_id = uuid.uuid4()
    from app.db.repositories.user_repo import UserRepository
    user_repo = UserRepository(db_session)
    await user_repo.create(id=user_id, display_name="Test", email="stale@t.com", password_hash="h")

    repo = DeviceRegistrationRepository(db_session)
    reg = await repo.upsert(user_id=user_id, platform="ios", token="stale-tok")

    from sqlalchemy import update
    await db_session.execute(
        update(DeviceRegistration)
        .where(DeviceRegistration.id == reg.id)
        .values(last_seen_at=datetime.now(timezone.utc) - timedelta(days=90))
    )
    await db_session.flush()

    cutoff = datetime.now(timezone.utc) - timedelta(days=60)
    stale = await repo.list_stale(cutoff)
    assert len(stale) == 1
    assert stale[0].token == "stale-tok"
