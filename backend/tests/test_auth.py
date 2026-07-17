from uuid import UUID

import httpx
import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr

from app.auth.dependencies import get_current_user
from app.auth.models import AuthenticatedUser
from app.auth.service import InvalidAccessTokenError, SupabaseAuthService
from app.core.config import Settings
from app.main import app


@pytest.mark.asyncio
async def test_auth_service_returns_google_user() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.headers["Authorization"] == "Bearer valid-token"
        return httpx.Response(
            200,
            json={
                "id": "11111111-1111-1111-1111-111111111111",
                "email": "user@example.com",
                "user_metadata": {
                    "full_name": "Demo User",
                    "role": "FARMER",
                },
                "app_metadata": {"provider": "google"},
            },
        )

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
        service = SupabaseAuthService(
            Settings(
                supabase_url="https://example.supabase.co",
                supabase_anon_key=SecretStr("public-key"),
            ),
            client,
        )
        user = await service.verify_access_token("valid-token")

    assert user.email == "user@example.com"
    assert user.provider == "google"
    assert user.role == "FARMER"


@pytest.mark.asyncio
async def test_auth_service_rejects_invalid_token() -> None:
    transport = httpx.MockTransport(lambda _: httpx.Response(401))
    async with httpx.AsyncClient(transport=transport) as client:
        service = SupabaseAuthService(
            Settings(
                supabase_url="https://example.supabase.co",
                supabase_anon_key=SecretStr("public-key"),
            ),
            client,
        )
        with pytest.raises(InvalidAccessTokenError):
            await service.verify_access_token("invalid-token")


def test_auth_me_requires_bearer_token() -> None:
    with TestClient(app) as client:
        response = client.get("/api/v1/auth/me")

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "UNAUTHORIZED"


def test_auth_me_returns_current_user() -> None:
    async def override_current_user() -> AuthenticatedUser:
        return AuthenticatedUser(
            id=UUID("11111111-1111-1111-1111-111111111111"),
            email="user@example.com",
            name="Demo User",
            provider="google",
        )

    app.dependency_overrides[get_current_user] = override_current_user
    try:
        with TestClient(app) as client:
            response = client.get("/api/v1/auth/me")
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 200
    assert response.json()["data"]["provider"] == "google"
