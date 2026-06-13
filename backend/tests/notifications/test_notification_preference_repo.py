import uuid

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.repositories.notification_preference_repo import NotificationPreferenceRepository


@pytest.mark.asyncio
async def test_seed_defaults(db_session: AsyncSession):
    user_id = uuid.uuid4()
    from app.db.repositories.user_repo import UserRepository
    await UserRepository(db_session).create(
        id=user_id, display_name="Test", email="seed@t.com", password_hash="h"
    )

    repo = NotificationPreferenceRepository(db_session)
    await repo.seed_defaults(user_id)
    prefs = await repo.list_for_user(user_id)
    assert len(prefs) == 5
    event_types = {p.event_type for p in prefs}
    assert event_types == {
        "ready_changed", "session_proposed", "session_updated",
        "session_rsvp_updated", "join_request_pending",
    }


@pytest.mark.asyncio
async def test_seed_defaults_idempotent(db_session: AsyncSession):
    user_id = uuid.uuid4()
    from app.db.repositories.user_repo import UserRepository
    await UserRepository(db_session).create(
        id=user_id, display_name="Test", email="idem@t.com", password_hash="h"
    )

    repo = NotificationPreferenceRepository(db_session)
    await repo.seed_defaults(user_id)
    await repo.seed_defaults(user_id)
    prefs = await repo.list_for_user(user_id)
    assert len(prefs) == 5


@pytest.mark.asyncio
async def test_has_preferences(db_session: AsyncSession):
    user_id = uuid.uuid4()
    from app.db.repositories.user_repo import UserRepository
    await UserRepository(db_session).create(
        id=user_id, display_name="Test", email="has@t.com", password_hash="h"
    )

    repo = NotificationPreferenceRepository(db_session)
    assert await repo.has_preferences(user_id) is False
    await repo.seed_defaults(user_id)
    assert await repo.has_preferences(user_id) is True


@pytest.mark.asyncio
async def test_get_for_user_event(db_session: AsyncSession):
    user_id = uuid.uuid4()
    from app.db.repositories.user_repo import UserRepository
    await UserRepository(db_session).create(
        id=user_id, display_name="Test", email="evt@t.com", password_hash="h"
    )

    repo = NotificationPreferenceRepository(db_session)
    await repo.seed_defaults(user_id)

    pref = await repo.get_for_user_event(user_id, "session_proposed")
    assert pref is not None
    assert pref.enabled is True

    missing = await repo.get_for_user_event(user_id, "nonexistent")
    assert missing is None


@pytest.mark.asyncio
async def test_get_group_preference(db_session: AsyncSession):
    user_id = uuid.uuid4()
    group_id = uuid.uuid4()
    from app.db.repositories.user_repo import UserRepository
    await UserRepository(db_session).create(
        id=user_id, display_name="Test", email="grp@t.com", password_hash="h"
    )

    repo = NotificationPreferenceRepository(db_session)
    pref = await repo.get_group_preference(user_id, group_id)
    assert pref is None


@pytest.mark.asyncio
async def test_default_conditions(db_session: AsyncSession):
    user_id = uuid.uuid4()
    from app.db.repositories.user_repo import UserRepository
    await UserRepository(db_session).create(
        id=user_id, display_name="Test", email="cond@t.com", password_hash="h"
    )

    repo = NotificationPreferenceRepository(db_session)
    await repo.seed_defaults(user_id)

    session_updated_pref = await repo.get_for_user_event(user_id, "session_updated")
    assert session_updated_pref.conditions == {"only_if_rsvp": ["in", "maybe"]}

    join_pref = await repo.get_for_user_event(user_id, "join_request_pending")
    assert join_pref.conditions == {"only_if_role": ["owner", "admin"]}
