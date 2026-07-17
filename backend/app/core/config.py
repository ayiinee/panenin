from functools import lru_cache

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Panenin API"
    app_env: str = "development"
    app_debug: bool = False
    api_v1_prefix: str = "/api/v1"
    frontend_origin: str = "http://localhost:3000"
    supabase_url: str = ""
    supabase_anon_key: SecretStr = SecretStr("")
    supabase_service_role_key: SecretStr = SecretStr("")
    database_url: SecretStr = SecretStr("")
    test_database_url: SecretStr = SecretStr("")
    panenin_ai_service_token_hash: SecretStr = SecretStr("")
    panenin_agent_contract_version: str = "0.1.0"
    whatsapp_link_code_ttl_seconds: int = 600
    bot_action_ttl_seconds: int = 600
    order_reservation_ttl_seconds: int = 86400
    confirmation_code_pepper: SecretStr = SecretStr("")

    model_config = SettingsConfigDict(
        env_file=(".env", "../.env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
