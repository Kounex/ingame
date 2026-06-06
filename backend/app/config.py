import json
from typing import Annotated

from pydantic import AliasChoices, Field, field_validator
from pydantic_settings import BaseSettings, NoDecode


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
    apple_client_ids: Annotated[list[str], NoDecode] = Field(
        default=[
            "ingame.kounex.com",
            "com.example.ingame",
            "com.kounex.ingame.web",
        ],
        validation_alias=AliasChoices(
            "INGAME_APPLE_CLIENT_IDS",
            "INGAME_APPLE_CLIENT_ID",
        ),
    )
    avatar_storage_bucket: str = ""
    avatar_storage_region: str = "auto"
    avatar_storage_endpoint_url: str = ""
    avatar_storage_upload_base_url: str = ""
    avatar_storage_access_key_id: str = ""
    avatar_storage_secret_access_key: str = ""
    avatar_storage_public_base_url: str = ""
    avatar_upload_max_file_size_bytes: int = 2 * 1024 * 1024
    avatar_upload_presign_expires_seconds: int = 300

    cors_origins: Annotated[list[str], NoDecode] = Field(
        default=["http://localhost:3000", "http://localhost:8080"],
        validation_alias=AliasChoices(
            "INGAME_CORS_ALLOW_ORIGINS",
            "INGAME_CORS_ORIGINS",
        ),
    )
    cors_allow_all: bool = False

    debug: bool = False

    @field_validator("cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, value: object) -> object:
        if not isinstance(value, str):
            return value

        value = value.strip()
        if not value:
            return []
        if value.startswith("["):
            return json.loads(value)
        return [item.strip() for item in value.split(",") if item.strip()]

    @field_validator("apple_client_ids", mode="before")
    @classmethod
    def parse_apple_client_ids(cls, value: object) -> object:
        if not isinstance(value, str):
            return value

        value = value.strip()
        if not value:
            return []
        if value.startswith("["):
            return json.loads(value)
        return [item.strip() for item in value.split(",") if item.strip()]


settings = Settings()
