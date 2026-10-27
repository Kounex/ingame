import asyncio

import bcrypt

# bcrypt only uses the first 72 bytes. 4.x truncated silently, 5.x raises
# ValueError instead; truncating here keeps 4.x behaviour, so existing
# hashes still verify.
_BCRYPT_MAX_BYTES = 72


async def hash_password(password: str) -> str:
    return await asyncio.to_thread(_hash_sync, password)


async def verify_password(plain_password: str, hashed_password: str) -> bool:
    return await asyncio.to_thread(_verify_sync, plain_password, hashed_password)


def _hash_sync(password: str) -> str:
    password_bytes = password.encode("utf-8")[:_BCRYPT_MAX_BYTES]
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password_bytes, salt)
    return hashed.decode("utf-8")


def _verify_sync(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(
        plain_password.encode("utf-8")[:_BCRYPT_MAX_BYTES],
        hashed_password.encode("utf-8"),
    )
