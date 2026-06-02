import json
import time

from app.redis.client import redis_pool

CONNECTION_ONLINE = "online"
CONNECTION_AWAY = "away"
CONNECTION_OFFLINE = "offline"
READY_TTL_SECONDS = 8 * 60 * 60


def _connection_key(user_id: str) -> str:
    return f"user:{user_id}:connection"


def _group_online_key(group_id: str) -> str:
    return f"group:{group_id}:online"


def _group_ready_users_key(group_id: str) -> str:
    return f"group:{group_id}:ready_users"


def _group_ready_key(group_id: str, user_id: str) -> str:
    return f"group:{group_id}:ready:{user_id}"


async def set_user_connection(user_id: str, state: str) -> None:
    if state not in {CONNECTION_ONLINE, CONNECTION_AWAY}:
        state = CONNECTION_ONLINE
    redis = redis_pool.client
    await redis.hset(
        _connection_key(user_id),
        mapping={"state": state, "since": str(int(time.time()))},
    )


async def get_user_connection(user_id: str) -> str:
    redis = redis_pool.client
    data = await redis.hgetall(_connection_key(user_id))
    if not data:
        return CONNECTION_OFFLINE
    return data.get("state", CONNECTION_OFFLINE)


async def clear_user_connection(user_id: str) -> None:
    redis = redis_pool.client
    await redis.delete(_connection_key(user_id))


async def set_group_ready(group_id: str, user_id: str) -> dict[str, str]:
    now = int(time.time())
    expires_at = now + READY_TTL_SECONDS
    payload = {"since": str(now), "expires_at": str(expires_at)}
    redis = redis_pool.client
    await redis.sadd(_group_ready_users_key(group_id), user_id)
    await redis.setex(
        _group_ready_key(group_id, user_id),
        READY_TTL_SECONDS,
        json.dumps(payload),
    )
    return payload


async def clear_group_ready(group_id: str, user_id: str) -> None:
    redis = redis_pool.client
    await redis.srem(_group_ready_users_key(group_id), user_id)
    await redis.delete(_group_ready_key(group_id, user_id))


async def get_group_ready(group_id: str, user_id: str) -> dict[str, str] | None:
    redis = redis_pool.client
    raw = await redis.get(_group_ready_key(group_id, user_id))
    if raw is None:
        await redis.srem(_group_ready_users_key(group_id), user_id)
        return None

    payload = json.loads(raw)
    if int(payload["expires_at"]) <= int(time.time()):
        await clear_group_ready(group_id, user_id)
        return None
    return payload


async def sweep_expired_ready(group_id: str) -> list[str]:
    redis = redis_pool.client
    user_ids = await redis.smembers(_group_ready_users_key(group_id))
    expired: list[str] = []
    for user_id in user_ids:
        if await get_group_ready(group_id, user_id) is None:
            expired.append(user_id)
    return expired


async def get_group_online_members(group_id: str) -> set[str]:
    redis = redis_pool.client
    key = _group_online_key(group_id)
    members = await redis.smembers(key)
    return set(members)


async def get_group_presence_snapshot(group_id: str) -> dict:
    await sweep_expired_ready(group_id)
    redis = redis_pool.client
    online_user_ids = await get_group_online_members(group_id)
    ready_user_ids = set(await redis.smembers(_group_ready_users_key(group_id)))
    user_ids = sorted(online_user_ids | ready_user_ids)
    members: list[dict] = []

    for user_id in user_ids:
        connection = await get_user_connection(user_id)
        ready_data = await get_group_ready(group_id, user_id)
        member: dict = {
            "user_id": user_id,
            "connection": connection,
            "ready": ready_data is not None,
        }
        if ready_data is not None:
            member["ready_since"] = ready_data["since"]
            member["ready_expires_at"] = ready_data["expires_at"]
        members.append(member)

    return {
        "group_id": group_id,
        "members": members,
    }


async def add_to_group_online(group_id: str, user_id: str) -> None:
    redis = redis_pool.client
    key = _group_online_key(group_id)
    await redis.sadd(key, user_id)


async def remove_from_group_online(group_id: str, user_id: str) -> None:
    redis = redis_pool.client
    key = _group_online_key(group_id)
    await redis.srem(key, user_id)
