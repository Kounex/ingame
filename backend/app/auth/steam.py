import httpx

from app.config import settings

STEAM_OPENID_URL = "https://steamcommunity.com/openid/login"


async def validate_steam_login(params: dict) -> str:
    """Validate Steam OpenID response. Returns Steam ID on success."""
    validation_params = dict(params)
    validation_params["openid.mode"] = "check_authentication"

    async with httpx.AsyncClient() as client:
        response = await client.post(STEAM_OPENID_URL, data=validation_params)

    if "is_valid:true" not in response.text:
        raise ValueError("Steam OpenID validation failed")

    claimed_id = params.get("openid.claimed_id", "")
    # Steam claimed_id format: https://steamcommunity.com/openid/id/<steam_id>
    steam_id = claimed_id.split("/")[-1]
    if not steam_id.isdigit():
        raise ValueError("Invalid Steam ID format")

    return steam_id


async def get_steam_profile(steam_id: str) -> dict:
    """Fetch Steam user profile via Web API."""
    url = "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/"
    params = {"key": settings.steam_api_key, "steamids": steam_id}

    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params)
        response.raise_for_status()

    data = response.json()
    players = data.get("response", {}).get("players", [])
    if not players:
        raise ValueError(f"Steam profile not found for ID: {steam_id}")

    player = players[0]
    return {
        "steam_id": player["steamid"],
        "display_name": player.get("personaname", f"Steam_{steam_id}"),
        "avatar_url": player.get("avatarfull"),
    }
