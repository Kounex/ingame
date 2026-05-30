from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    model_config = {"env_prefix": "INGAME_", "env_file": ".env"}

    database_url: str = "postgresql+asyncpg://ingame:ingame@localhost:5432/ingame"
    redis_url: str = "redis://localhost:6379"

    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 30

    steam_api_key: str = ""
    apple_team_id: str = ""
    apple_key_id: str = ""
    apple_client_id: str = "ingame.kounex.com"

    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:8080"]
    cors_allow_all: bool = False

    debug: bool = False


settings = Settings()
