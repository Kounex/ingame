import httpx
from jose import jwt as jose_jwt, JWTError

from app.config import settings

APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys"


async def _get_apple_public_keys() -> list[dict]:
    """Fetch Apple's public keys for token verification."""
    async with httpx.AsyncClient() as client:
        response = await client.get(APPLE_KEYS_URL)
        response.raise_for_status()
    return response.json()["keys"]


async def validate_apple_token(identity_token: str) -> dict:
    """Validate Apple identity token. Returns user info (sub, email)."""
    try:
        unverified_header = jose_jwt.get_unverified_header(identity_token)
    except JWTError as e:
        raise ValueError(f"Invalid Apple token header: {e}") from e

    kid = unverified_header.get("kid")
    if not kid:
        raise ValueError("Apple token missing key ID")

    apple_keys = await _get_apple_public_keys()
    matching_key = next((k for k in apple_keys if k["kid"] == kid), None)
    if not matching_key:
        raise ValueError("Apple public key not found for token")

    payload = None
    last_error: JWTError | None = None
    for audience in settings.apple_client_ids:
        try:
            payload = jose_jwt.decode(
                identity_token,
                matching_key,
                algorithms=["RS256"],
                audience=audience,
                issuer="https://appleid.apple.com",
            )
            break
        except JWTError as e:
            last_error = e

    if payload is None:
        message = last_error or "no configured Apple audience matched"
        raise ValueError(f"Apple token verification failed: {message}")

    return {
        "sub": payload["sub"],
        "email": payload.get("email"),
    }
