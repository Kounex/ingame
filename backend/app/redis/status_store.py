import time

from app.redis.client import redis_pool

VALID_STATES = {"online", "ready", "away", "offline"}


async def set_user_status(
    user_id: str, state: str, game: str | None = None
) -> None:
    if state not in VALID_STATES:
        state = "online"
    redis = redis_pool.client
    key = f"user:{user_id}:status"
    data = {"state": state, "since": str(int(time.time()))}
    if game:
        data["game"] = game
    await redis.hset(key, mapping=data)


async def get_user_status(user_id: str) -> dict | None:
    redis = redis_pool.client
    key = f"user:{user_id}:status"
    data = await redis.hgetall(key)
    return data if data else None


async def clear_user_status(user_id: str) -> None:
    redis = redis_pool.client
    key = f"user:{user_id}:status"
    await redis.delete(key)


async def get_group_online_members(group_id: str) -> set[str]:
    redis = redis_pool.client
    key = f"group:{group_id}:online"
    members = await redis.smembers(key)
    return set(members)


async def get_group_presence_snapshot(group_id: str) -> dict:
    online_user_ids = sorted(await get_group_online_members(group_id))
    statuses: list[dict] = []

    for user_id in online_user_ids:
        status = await get_user_status(user_id)
        if status is None:
            status = {"state": "online", "since": str(int(time.time()))}

        statuses.append(
            {
                "user_id": user_id,
                "state": status.get("state", "online"),
                "game": status.get("game"),
                "since": status.get("since"),
            }
        )

    return {
        "group_id": group_id,
        "online_user_ids": online_user_ids,
        "statuses": statuses,
    }


async def add_to_group_online(group_id: str, user_id: str) -> None:
    redis = redis_pool.client
    key = f"group:{group_id}:online"
    await redis.sadd(key, user_id)


async def remove_from_group_online(group_id: str, user_id: str) -> None:
    redis = redis_pool.client
    key = f"group:{group_id}:online"
    await redis.srem(key, user_id)
