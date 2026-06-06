import redis.asyncio as aioredis

from app.config import settings


class RedisPool:
    def __init__(self) -> None:
        self._pool: aioredis.Redis | None = None
        self._pubsub_pool: aioredis.Redis | None = None

    async def initialize(self) -> None:
        self._pool = aioredis.from_url(settings.redis_url, decode_responses=True)
        # Pub/sub listeners must be able to block on idle reads without tripping
        # the generic Redis command timeout used by ordinary request paths.
        self._pubsub_pool = aioredis.from_url(
            settings.redis_url,
            decode_responses=True,
            socket_timeout=None,
            health_check_interval=30,
        )

    @property
    def client(self) -> aioredis.Redis:
        if self._pool is None:
            raise RuntimeError("Redis pool not initialized")
        return self._pool

    @property
    def pubsub_client(self) -> aioredis.Redis:
        if self._pubsub_pool is None:
            raise RuntimeError("Redis pool not initialized")
        return self._pubsub_pool

    async def close(self) -> None:
        if self._pubsub_pool:
            await self._pubsub_pool.close()
        if self._pool:
            await self._pool.close()


redis_pool = RedisPool()
