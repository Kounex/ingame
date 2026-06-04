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
