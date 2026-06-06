from unittest.mock import call, patch

import pytest

from app.config import settings
from app.redis.client import RedisPool


@pytest.mark.asyncio
async def test_redis_pool_uses_dedicated_pubsub_client_configuration():
    pool = RedisPool()
    primary_client = object()
    pubsub_client = object()

    with patch(
        "app.redis.client.aioredis.from_url",
        side_effect=[primary_client, pubsub_client],
    ) as from_url:
        await pool.initialize()

    assert pool.client is primary_client
    assert pool.pubsub_client is pubsub_client
    assert from_url.call_args_list == [
        call(settings.redis_url, decode_responses=True),
        call(
            settings.redis_url,
            decode_responses=True,
            socket_timeout=None,
            health_check_interval=30,
        ),
    ]
