import uuid
from unittest.mock import AsyncMock, patch

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.notifications.dispatcher import dispatch_notification


@pytest.mark.asyncio
async def test_dispatch_skips_actor(db_session: AsyncSession):
    actor_id = uuid.uuid4()
    group_id = uuid.uuid4()

    from app.db.repositories.user_repo import UserRepository
    user_repo = UserRepository(db_session)
    await user_repo.create(id=actor_id, display_name="Actor", email="actor@t.com", password_hash="h")

    from app.db.models.group import Group, GroupMembership
    group = Group(id=group_id, name="Test Group", invite_code="ABC123", created_by=actor_id)
    db_session.add(group)
    await db_session.flush()

    membership = GroupMembership(user_id=actor_id, group_id=group_id, role="owner")
    db_session.add(membership)
    await db_session.flush()

    with patch("app.notifications.dispatcher.send_push", new_callable=AsyncMock) as mock_send:
        await dispatch_notification(
            db=db_session,
            event_type="session_proposed",
            group_id=group_id,
            actor_user_id=actor_id,
            payload={"session_title": "Test"},
        )
        mock_send.assert_not_called()


@pytest.mark.asyncio
async def test_dispatch_sends_to_other_members(db_session: AsyncSession):
    actor_id = uuid.uuid4()
    member_id = uuid.uuid4()
    group_id = uuid.uuid4()

    from app.db.repositories.user_repo import UserRepository
    user_repo = UserRepository(db_session)
    await user_repo.create(id=actor_id, display_name="Actor", email="a2@t.com", password_hash="h")
    await user_repo.create(id=member_id, display_name="Member", email="m2@t.com", password_hash="h")

    from app.db.models.group import Group, GroupMembership
    group = Group(id=group_id, name="Test Group", invite_code="XYZ789", created_by=actor_id)
    db_session.add(group)
    await db_session.flush()

    db_session.add(GroupMembership(user_id=actor_id, group_id=group_id, role="owner"))
    db_session.add(GroupMembership(user_id=member_id, group_id=group_id, role="member"))
    await db_session.flush()

    from app.db.repositories.device_registration_repo import DeviceRegistrationRepository
    device_repo = DeviceRegistrationRepository(db_session)
    await device_repo.upsert(user_id=member_id, platform="ios", token="member-token")

    from app.db.repositories.notification_preference_repo import NotificationPreferenceRepository
    pref_repo = NotificationPreferenceRepository(db_session)
    await pref_repo.seed_defaults(member_id)

    with patch("app.notifications.dispatcher.send_push", new_callable=AsyncMock, return_value=True) as mock_send:
        await dispatch_notification(
            db=db_session,
            event_type="session_proposed",
            group_id=group_id,
            actor_user_id=actor_id,
            payload={"session_title": "Valorant Night", "formatted_time": "8 PM"},
        )
        mock_send.assert_called_once()
        call_kwargs = mock_send.call_args.kwargs
        assert call_kwargs["token"] == "member-token"
        assert "Valorant Night" in call_kwargs["body"]


@pytest.mark.asyncio
async def test_dispatch_respects_disabled_preference(db_session: AsyncSession):
    actor_id = uuid.uuid4()
    member_id = uuid.uuid4()
    group_id = uuid.uuid4()

    from app.db.repositories.user_repo import UserRepository
    user_repo = UserRepository(db_session)
    await user_repo.create(id=actor_id, display_name="Actor", email="a3@t.com", password_hash="h")
    await user_repo.create(id=member_id, display_name="Member", email="m3@t.com", password_hash="h")

    from app.db.models.group import Group, GroupMembership
    group = Group(id=group_id, name="Test Group", invite_code="DIS123", created_by=actor_id)
    db_session.add(group)
    await db_session.flush()
    db_session.add(GroupMembership(user_id=actor_id, group_id=group_id, role="owner"))
    db_session.add(GroupMembership(user_id=member_id, group_id=group_id, role="member"))
    await db_session.flush()

    from app.db.repositories.device_registration_repo import DeviceRegistrationRepository
    await DeviceRegistrationRepository(db_session).upsert(user_id=member_id, platform="ios", token="dis-token")

    from app.db.repositories.notification_preference_repo import NotificationPreferenceRepository
    pref_repo = NotificationPreferenceRepository(db_session)
    await pref_repo.seed_defaults(member_id)

    pref = await pref_repo.get_for_user_event(member_id, "session_proposed")
    pref.enabled = False
    await db_session.flush()

    with patch("app.notifications.dispatcher.send_push", new_callable=AsyncMock) as mock_send:
        await dispatch_notification(
            db=db_session,
            event_type="session_proposed",
            group_id=group_id,
            actor_user_id=actor_id,
            payload={"session_title": "Test"},
        )
        mock_send.assert_not_called()
