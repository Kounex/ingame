from app.config import Settings


def test_settings_accepts_release_cors_env_name(monkeypatch):
    monkeypatch.setenv("INGAME_CORS_ALLOW_ORIGINS", "https://app.in-game.app")
    monkeypatch.delenv("INGAME_CORS_ORIGINS", raising=False)

    settings = Settings()

    assert settings.cors_origins == ["https://app.in-game.app"]


def test_settings_accepts_comma_separated_legacy_cors_origins(monkeypatch):
    monkeypatch.delenv("INGAME_CORS_ALLOW_ORIGINS", raising=False)
    monkeypatch.setenv(
        "INGAME_CORS_ORIGINS",
        "https://app.in-game.app, https://admin.in-game.app",
    )

    settings = Settings()

    assert settings.cors_origins == [
        "https://app.in-game.app",
        "https://admin.in-game.app",
    ]


def test_settings_accepts_comma_separated_apple_client_ids(monkeypatch):
    monkeypatch.setenv(
        "INGAME_APPLE_CLIENT_IDS",
        "ingame.kounex.com, com.ingame.web",
    )

    settings = Settings()

    assert settings.apple_client_ids == ["ingame.kounex.com", "com.ingame.web"]


def test_settings_uses_legacy_single_apple_client_id_env_name(monkeypatch):
    monkeypatch.delenv("INGAME_APPLE_CLIENT_IDS", raising=False)
    monkeypatch.setenv("INGAME_APPLE_CLIENT_ID", "com.ingame.web")

    settings = Settings()

    assert settings.apple_client_ids == ["com.ingame.web"]
