from functools import lru_cache

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class WhatsAppSettings(BaseSettings):
    app_env: str = "development"
    panenin_core_api_url: str = "http://127.0.0.1:8001"
    panenin_ai_service_token: SecretStr = SecretStr("")
    whatsapp_subject_pepper: SecretStr = SecretStr("")
    fonnte_token: SecretStr = SecretStr("")
    fonnte_webhook_secret: SecretStr = SecretStr("")
    fonnte_api_url: str = "https://api.fonnte.com"
    whatsapp_demo_ui_enabled: bool = True

    model_config = SettingsConfigDict(
        env_file=(".env", "../.env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_whatsapp_settings() -> WhatsAppSettings:
    return WhatsAppSettings()

