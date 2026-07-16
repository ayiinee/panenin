from functools import lru_cache

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Panenin API"
    api_v1_prefix: str = "/api/v1"
    frontend_origin: str = "http://localhost:3000"
    supabase_url: str = ""
    supabase_anon_key: SecretStr = SecretStr("")

    model_config = SettingsConfigDict(
        env_file=(".env", "../.env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
