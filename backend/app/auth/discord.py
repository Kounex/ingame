from datetime import datetime, timedelta, timezone

import httpx

from app.config import settings

DISCORD_TOKEN_URL = "https://discord.com/api/oauth2/token"
DISCORD_ME_URL = "https://discord.com/api/users/@me"


async def exchange_discord_code(
    code: str,
    *,
    code_verifier: str,
    redirect_uri: str,
) -> dict[str, object]:
    async with httpx.AsyncClient() as client:
        response = await client.post(
            DISCORD_TOKEN_URL,
            data={
                "client_id": settings.discord_client_id,
                "grant_type": "authorization_code",
                "code": code,
                "redirect_uri": redirect_uri,
                "code_verifier": code_verifier,
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )
        response.raise_for_status()
    return response.json()


async def refresh_discord_token(refresh_token: str) -> dict[str, object]:
    async with httpx.AsyncClient() as client:
        response = await client.post(
            DISCORD_TOKEN_URL,
            data={
                "client_id": settings.discord_client_id,
                "grant_type": "refresh_token",
                "refresh_token": refresh_token,
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )
        response.raise_for_status()
    return response.json()


def discord_access_expiry(expires_in: int | None) -> datetime | None:
    if expires_in is None:
        return None
    return datetime.now(timezone.utc) + timedelta(seconds=expires_in)


async def get_discord_profile(access_token: str) -> dict[str, str | None]:
    async with httpx.AsyncClient() as client:
        response = await client.get(
            DISCORD_ME_URL,
            headers={"Authorization": f"Bearer {access_token}"},
        )
        response.raise_for_status()

    data = response.json()
    external_id = data["id"]
    avatar_hash = data.get("avatar")
    avatar_url = (
        f"https://cdn.discordapp.com/avatars/{external_id}/{avatar_hash}.png"
        if avatar_hash
        else None
    )
    username = data.get("username")
    display_name = data.get("global_name") or username
    return {
        "external_id": external_id,
        "username": username,
        "display_name": display_name,
        "email": data.get("email"),
        "avatar_url": avatar_url,
        "profile_url": f"https://discord.com/users/{external_id}",
    }
