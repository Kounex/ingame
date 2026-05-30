import json
from collections.abc import AsyncGenerator

from app.redis.client import redis_pool


async def publish_event(channel: str, event_data: dict) -> None:
    redis = redis_pool.client
    await redis.publish(channel, json.dumps(event_data))


async def subscribe_to_channels(channels: list[str]) -> AsyncGenerator[dict]:
    redis = redis_pool.client
    pubsub = redis.pubsub()
    await pubsub.subscribe(*channels)
    try:
        async for message in pubsub.listen():
            if message["type"] == "message":
                data = json.loads(message["data"])
                yield data
    finally:
        await pubsub.unsubscribe(*channels)
        await pubsub.close()


async def subscribe_to_patterns(patterns: list[str]) -> AsyncGenerator[dict]:
    redis = redis_pool.client
    pubsub = redis.pubsub()
    await pubsub.psubscribe(*patterns)
    try:
        async for message in pubsub.listen():
            if message["type"] == "pmessage":
                data = json.loads(message["data"])
                yield data
    finally:
        await pubsub.punsubscribe(*patterns)
        await pubsub.close()
