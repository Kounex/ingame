import asyncio
import fnmatch
import uuid
from collections.abc import AsyncGenerator
from unittest.mock import AsyncMock, patch

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import event
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.db.database import Base, get_db
from app.main import app

TEST_DATABASE_URL = "sqlite+aiosqlite:///./test.db"

engine = create_async_engine(TEST_DATABASE_URL, echo=False)
TestingSessionLocal = async_sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)


@event.listens_for(engine.sync_engine, "connect")
def _register_sqlite_functions(dbapi_conn, connection_record):
    dbapi_conn.create_function("gen_random_uuid", 0, lambda: str(uuid.uuid4()))


class FakeRedis:
    """In-memory Redis replacement for tests."""

    def __init__(self):
        self._store: dict[str, str] = {}
        self._hashes: dict[str, dict[str, str]] = {}
        self._sets: dict[str, set[str]] = {}
        self._pubsubs: list["FakePubSub"] = []

    async def get(self, key: str) -> str | None:
        return self._store.get(key)

    async def setex(self, key: str, ttl: int, value: str) -> None:
        self._store[key] = value

    async def delete(self, key: str) -> None:
        self._store.pop(key, None)
        self._hashes.pop(key, None)
        self._sets.pop(key, None)

    async def hset(self, key: str, mapping: dict[str, str]) -> None:
        self._hashes.setdefault(key, {}).update(mapping)

    async def hgetall(self, key: str) -> dict[str, str]:
        return dict(self._hashes.get(key, {}))

    async def sadd(self, key: str, *values: str) -> None:
        self._sets.setdefault(key, set()).update(values)

    async def srem(self, key: str, *values: str) -> None:
        members = self._sets.setdefault(key, set())
        for value in values:
            members.discard(value)

    async def smembers(self, key: str) -> set[str]:
        return set(self._sets.get(key, set()))

    async def publish(self, channel: str, data: str) -> None:
        for pubsub in list(self._pubsubs):
            await pubsub.push(channel, data)

    def pubsub(self) -> "FakePubSub":
        pubsub = FakePubSub(self)
        self._pubsubs.append(pubsub)
        return pubsub

    def reset(self) -> None:
        self._store.clear()
        self._hashes.clear()
        self._sets.clear()
        for pubsub in list(self._pubsubs):
            pubsub.close_sync()
        self._pubsubs.clear()


class FakePubSub:
    def __init__(self, redis: FakeRedis):
        self._redis = redis
        self._queue: asyncio.Queue[dict | None] = asyncio.Queue()
        self._channels: set[str] = set()
        self._patterns: set[str] = set()
        self._closed = False

    async def subscribe(self, *channels: str) -> None:
        self._channels.update(channels)

    async def psubscribe(self, *patterns: str) -> None:
        self._patterns.update(patterns)

    async def unsubscribe(self, *channels: str) -> None:
        for channel in channels:
            self._channels.discard(channel)

    async def punsubscribe(self, *patterns: str) -> None:
        for pattern in patterns:
            self._patterns.discard(pattern)

    async def listen(self):
        while True:
            message = await self._queue.get()
            if message is None:
                break
            yield message

    async def push(self, channel: str, data: str) -> None:
        if self._closed:
            return
        if channel in self._channels:
            await self._queue.put({"type": "message", "channel": channel, "data": data})
        for pattern in self._patterns:
            if fnmatch.fnmatch(channel, pattern):
                await self._queue.put(
                    {
                        "type": "pmessage",
                        "pattern": pattern,
                        "channel": channel,
                        "data": data,
                    }
                )

    async def close(self) -> None:
        self.close_sync()

    def close_sync(self) -> None:
        if self._closed:
            return
        self._closed = True
        self._queue.put_nowait(None)


_fake_redis = FakeRedis()


class FakeRedisPool:
    @property
    def client(self):
        return _fake_redis

    async def initialize(self):
        pass

    async def close(self):
        pass


@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    _fake_redis.reset()
    fake_pool = FakeRedisPool()

    with (
        patch("app.api.v1.auth.service.redis_pool", fake_pool),
        patch("app.redis.pubsub.redis_pool", fake_pool),
        patch("app.redis.status_store.redis_pool", fake_pool),
        patch("app.redis.client.redis_pool", fake_pool),
        patch("app.ws.handlers.async_session_factory", TestingSessionLocal),
    ):
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        yield
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession]:
    async with TestingSessionLocal() as session:
        yield session


@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient]:
    async def override_get_db():
        try:
            yield db_session
            await db_session.commit()
        except Exception:
            await db_session.rollback()
            raise

    app.dependency_overrides[get_db] = override_get_db

    fake_pool = FakeRedisPool()
    with (
        patch("app.api.v1.auth.service.redis_pool", fake_pool),
        patch("app.redis.pubsub.redis_pool", fake_pool),
        patch("app.redis.status_store.redis_pool", fake_pool),
        patch("app.redis.client.redis_pool", fake_pool),
        patch("app.ws.handlers.async_session_factory", TestingSessionLocal),
    ):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            yield ac

    app.dependency_overrides.clear()


def make_user_id() -> uuid.UUID:
    return uuid.uuid4()
