import time

import pytest

from app.redis import status_store


@pytest.mark.asyncio
async def test_set_and_get_group_ready_includes_expiry_metadata():
    payload = await status_store.set_group_ready("group-1", "user-1")

    assert "since" in payload
    assert "expires_at" in payload
    assert int(payload["expires_at"]) - int(payload["since"]) == status_store.READY_TTL_SECONDS

    ready = await status_store.get_group_ready("group-1", "user-1")
    assert ready is not None
    assert ready["since"] == payload["since"]


@pytest.mark.asyncio
async def test_expired_ready_is_cleared_on_read(monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setattr(status_store, "READY_TTL_SECONDS", 1)
    await status_store.set_group_ready("group-1", "user-1")

    fixed_now = int(time.time()) + 2
    monkeypatch.setattr(time, "time", lambda: fixed_now)

    ready = await status_store.get_group_ready("group-1", "user-1")
    assert ready is None


@pytest.mark.asyncio
async def test_sweep_expired_ready_returns_cleared_user_ids(
    monkeypatch: pytest.MonkeyPatch,
):
    monkeypatch.setattr(status_store, "READY_TTL_SECONDS", 1)
    await status_store.set_group_ready("group-1", "user-1")
    await status_store.set_group_ready("group-1", "user-2")

    fixed_now = int(time.time()) + 2
    monkeypatch.setattr(time, "time", lambda: fixed_now)

    expired = await status_store.sweep_expired_ready("group-1")
    assert set(expired) == {"user-1", "user-2"}
