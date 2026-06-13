import uuid
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.device_registration import DeviceRegistration
from app.db.repositories.device_registration_repo import DeviceRegistrationRepository
from app.db.repositories.user_repo import UserRepository
from app.jobs.stale_token_janitor import run_stale_token_janitor_once


@pytest.mark.asyncio
async def test_revokes_stale_tokens(db_session: AsyncSession):
    user_id = uuid.uuid4()
    await UserRepository(db_session).create(
        id=user_id, display_name="Test", email="stale@j.com", password_hash="h"
    )

    device_repo = DeviceRegistrationRepository(db_session)
    reg = await device_repo.upsert(user_id=user_id, platform="ios", token="stale-j")

    # Backdate last_seen_at to 90 days ago
    await db_session.execute(
        update(DeviceRegistration)
        .where(DeviceRegistration.id == reg.id)
        .values(last_seen_at=datetime.now(timezone.utc) - timedelta(days=90))
    )
    await db_session.flush()

    revoked = await run_stale_token_janitor_once(db_session)
    assert revoked == 1

    refreshed = await device_repo.get_by_id(reg.id)
    assert refreshed.revoked_at is not None


@pytest.mark.asyncio
async def test_skips_recently_seen_tokens(db_session: AsyncSession):
    user_id = uuid.uuid4()
    await UserRepository(db_session).create(
        id=user_id, display_name="Test", email="recent@j.com", password_hash="h"
    )

    device_repo = DeviceRegistrationRepository(db_session)
    await device_repo.upsert(user_id=user_id, platform="ios", token="recent-j")

    revoked = await run_stale_token_janitor_once(db_session)
    assert revoked == 0


@pytest.mark.asyncio
async def test_skips_already_revoked_tokens(db_session: AsyncSession):
    user_id = uuid.uuid4()
    await UserRepository(db_session).create(
        id=user_id, display_name="Test", email="revoked@j.com", password_hash="h"
    )

    device_repo = DeviceRegistrationRepository(db_session)
    reg = await device_repo.upsert(user_id=user_id, platform="ios", token="rev-j")
    await device_repo.revoke(reg.id)

    await db_session.execute(
        update(DeviceRegistration)
        .where(DeviceRegistration.id == reg.id)
        .values(last_seen_at=datetime.now(timezone.utc) - timedelta(days=90))
    )
    await db_session.flush()

    revoked = await run_stale_token_janitor_once(db_session)
    assert revoked == 0
