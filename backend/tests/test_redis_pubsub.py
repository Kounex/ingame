import json
from unittest.mock import patch

import pytest

from app.redis.pubsub import subscribe_to_patterns


class _PrimaryClient:
    def pubsub(self):
        raise AssertionError("subscribe_to_patterns should use the dedicated pubsub client")


class _RecordingPubSub:
    def __init__(self) -> None:
        self.subscribed_patterns: tuple[str, ...] | None = None
        self.unsubscribed_patterns: tuple[str, ...] | None = None
        self.closed = False

    async def psubscribe(self, *patterns: str) -> None:
        self.subscribed_patterns = patterns

    async def punsubscribe(self, *patterns: str) -> None:
        self.unsubscribed_patterns = patterns

    async def listen(self):
        yield {
            "type": "pmessage",
            "pattern": "group:*:events",
            "channel": "group:123:events",
            "data": json.dumps({"type": "ready_changed", "group_id": "123"}),
        }

    async def close(self) -> None:
        self.closed = True


class _PubSubClient:
    def __init__(self, pubsub: _RecordingPubSub) -> None:
        self._pubsub = pubsub

    def pubsub(self) -> _RecordingPubSub:
        return self._pubsub


class _RedisPoolStub:
    def __init__(self, pubsub: _RecordingPubSub) -> None:
        self.client = _PrimaryClient()
        self.pubsub_client = _PubSubClient(pubsub)


@pytest.mark.asyncio
async def test_subscribe_to_patterns_uses_dedicated_pubsub_client():
    pubsub = _RecordingPubSub()
    redis_pool = _RedisPoolStub(pubsub)

    with patch("app.redis.pubsub.redis_pool", redis_pool):
        events = [event async for event in subscribe_to_patterns(["group:*:events"])]

    assert events == [{"type": "ready_changed", "group_id": "123"}]
    assert pubsub.subscribed_patterns == ("group:*:events",)
    assert pubsub.unsubscribed_patterns == ("group:*:events",)
    assert pubsub.closed is True
