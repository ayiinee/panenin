from typing import Any

import httpx

from app.auth.models import AuthenticatedUser
from app.core.config import Settings


class InvalidAccessTokenError(Exception):
    pass


class AuthServiceUnavailableError(Exception):
    pass


class SupabaseAuthService:
    def __init__(
        self,
        settings: Settings,
        http_client: httpx.AsyncClient,
    ) -> None:
        self._settings = settings
        self._http_client = http_client

    async def verify_access_token(self, access_token: str) -> AuthenticatedUser:
        supabase_url = self._settings.supabase_url.rstrip("/")
        anon_key = self._settings.supabase_anon_key.get_secret_value()
        if not supabase_url or not anon_key:
            raise AuthServiceUnavailableError("Supabase belum dikonfigurasi.")

        try:
            response = await self._http_client.get(
                f"{supabase_url}/auth/v1/user",
                headers={
                    "apikey": anon_key,
                    "Authorization": f"Bearer {access_token}",
                },
            )
        except httpx.HTTPError as exc:
            raise AuthServiceUnavailableError(
                "Layanan autentikasi sedang tidak dapat dijangkau."
            ) from exc

        if response.status_code in {401, 403}:
            raise InvalidAccessTokenError("Sesi tidak valid atau sudah kedaluwarsa.")
        if response.is_error:
            raise AuthServiceUnavailableError(
                "Layanan autentikasi gagal memvalidasi sesi."
            )

        payload: dict[str, Any] = response.json()
        metadata = payload.get("user_metadata") or {}
        app_metadata = payload.get("app_metadata") or {}
        return AuthenticatedUser(
            id=payload["id"],
            email=payload.get("email"),
            name=metadata.get("full_name") or metadata.get("name"),
            provider=app_metadata.get("provider"),
        )
