from unittest.mock import AsyncMock, patch

import pytest
from jose import JWTError

from app.auth.apple import validate_apple_token


@pytest.mark.asyncio
async def test_validate_apple_token_accepts_all_configured_audiences():
    with (
        patch(
            "app.auth.apple.jose_jwt.get_unverified_header",
            return_value={"kid": "kid-1"},
        ),
        patch(
            "app.auth.apple._get_apple_public_keys",
            new=AsyncMock(return_value=[{"kid": "kid-1", "kty": "RSA"}]),
        ),
        patch(
            "app.auth.apple.settings.apple_client_ids",
            ["ingame.kounex.com", "com.kounex.ingame.web"],
        ),
        patch(
            "app.auth.apple.jose_jwt.decode",
            return_value={"sub": "apple-user-1", "email": "apple@example.com"},
        ) as decode,
    ):
        result = await validate_apple_token("apple.identity.token")

    assert result == {"sub": "apple-user-1", "email": "apple@example.com"}
    assert decode.call_args.kwargs["audience"] == "ingame.kounex.com"


@pytest.mark.asyncio
async def test_validate_apple_token_checks_configured_audiences_individually():
    def decode_side_effect(_token, _key, algorithms, audience, issuer):
        assert algorithms == ["RS256"]
        assert issuer == "https://appleid.apple.com"
        if not isinstance(audience, str):
            raise JWTError("audience must be a string or None")
        if audience != "com.kounex.ingame.web":
            raise JWTError("Invalid audience")
        return {"sub": "apple-user-1", "email": "apple@example.com"}

    with (
        patch(
            "app.auth.apple.jose_jwt.get_unverified_header",
            return_value={"kid": "kid-1"},
        ),
        patch(
            "app.auth.apple._get_apple_public_keys",
            new=AsyncMock(return_value=[{"kid": "kid-1", "kty": "RSA"}]),
        ),
        patch(
            "app.auth.apple.settings.apple_client_ids",
            ["ingame.kounex.com", "com.kounex.ingame.web"],
        ),
        patch(
            "app.auth.apple.jose_jwt.decode",
            side_effect=decode_side_effect,
        ),
    ):
        result = await validate_apple_token("apple.identity.token")

    assert result == {"sub": "apple-user-1", "email": "apple@example.com"}
