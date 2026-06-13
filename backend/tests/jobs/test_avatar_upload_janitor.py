import logging
from datetime import datetime, timedelta, timezone
from uuid import uuid4
from unittest.mock import patch

import pytest
from sqlalchemy import text

from app.db.repositories.avatar_upload_ledger_repo import AvatarUploadLedgerRepository
from app.db.repositories.user_repo import UserRepository
from app.jobs.avatar_upload_janitor import run_avatar_upload_janitor_once


async def _create_user(db_session, *, email_prefix: str):
    return await UserRepository(db_session).create(
        email=f"{email_prefix}-{uuid4()}@test.com",
        display_name="TTL Janitor User",
    )


@pytest.mark.asyncio
async def test_run_avatar_upload_janitor_deletes_expired_pending_upload(db_session):
    user = await _create_user(db_session, email_prefix="expired")
    repo = AvatarUploadLedgerRepository(db_session)
    record = await repo.create_pending(
        user_id=user.id,
        object_key=f"users/{user.id}/avatars/expired.webp",
        avatar_url=f"https://cdn.test/users/{user.id}/avatars/expired.webp",
    )
    await db_session.execute(
        text(
            "update avatar_upload_ledgers "
            "set created_at = :created_at "
            "where avatar_url = :avatar_url"
        ),
        {
            "created_at": datetime.now(timezone.utc) - timedelta(days=2),
            "avatar_url": record.avatar_url,
        },
    )
    await db_session.commit()

    with patch("app.jobs.avatar_upload_janitor.delete_avatar_object_by_key") as delete_avatar:
        deleted_count = await run_avatar_upload_janitor_once(db_session)

    assert deleted_count == 1
    delete_avatar.assert_called_once_with(record.object_key)
    assert await repo.get_by_avatar_url(record.avatar_url) is None


@pytest.mark.asyncio
async def test_run_avatar_upload_janitor_skips_committed_upload(db_session):
    user = await _create_user(db_session, email_prefix="committed")
    repo = AvatarUploadLedgerRepository(db_session)
    record = await repo.create_pending(
        user_id=user.id,
        object_key=f"users/{user.id}/avatars/committed.webp",
        avatar_url=f"https://cdn.test/users/{user.id}/avatars/committed.webp",
    )
    await repo.mark_committed(user_id=user.id, avatar_url=record.avatar_url)
    await db_session.execute(
        text(
            "update avatar_upload_ledgers "
            "set created_at = :created_at "
            "where avatar_url = :avatar_url"
        ),
        {
            "created_at": datetime.now(timezone.utc) - timedelta(days=2),
            "avatar_url": record.avatar_url,
        },
    )
    await db_session.commit()

    with patch("app.jobs.avatar_upload_janitor.delete_avatar_object_by_key") as delete_avatar:
        deleted_count = await run_avatar_upload_janitor_once(db_session)

    assert deleted_count == 0
    delete_avatar.assert_not_called()
    refreshed = await repo.get_by_avatar_url(record.avatar_url)
    assert refreshed is not None
    assert refreshed.committed_at is not None


@pytest.mark.asyncio
async def test_run_avatar_upload_janitor_logs_delete_failures_and_keeps_row_retryable(
    db_session,
    caplog: pytest.LogCaptureFixture,
):
    user = await _create_user(db_session, email_prefix="retryable")
    repo = AvatarUploadLedgerRepository(db_session)
    record = await repo.create_pending(
        user_id=user.id,
        object_key=f"users/{user.id}/avatars/retryable.webp",
        avatar_url=f"https://cdn.test/users/{user.id}/avatars/retryable.webp",
    )
    avatar_url = record.avatar_url
    await db_session.execute(
        text(
            "update avatar_upload_ledgers "
            "set created_at = :created_at "
            "where avatar_url = :avatar_url"
        ),
        {
            "created_at": datetime.now(timezone.utc) - timedelta(days=2),
            "avatar_url": record.avatar_url,
        },
    )
    await db_session.commit()
    caplog.set_level(logging.ERROR, logger="app.jobs.avatar_upload_janitor")

    with patch(
        "app.jobs.avatar_upload_janitor.delete_avatar_object_by_key",
        side_effect=RuntimeError("storage unavailable"),
    ):
        deleted_count = await run_avatar_upload_janitor_once(db_session)

    assert deleted_count == 0
    assert "Avatar upload janitor failed" in caplog.text
    assert await repo.get_by_avatar_url(avatar_url) is not None
