from collections.abc import AsyncIterator

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.auth.models import AuthenticatedUser
from app.auth.service import (
    AuthServiceUnavailableError,
    InvalidAccessTokenError,
    SupabaseAuthService,
)
from app.core.config import Settings, get_settings

bearer_scheme = HTTPBearer(auto_error=False)


async def get_auth_service(
    settings: Settings = Depends(get_settings),
) -> AsyncIterator[SupabaseAuthService]:
    async with httpx.AsyncClient(timeout=5.0) as http_client:
        yield SupabaseAuthService(settings, http_client)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    auth_service: SupabaseAuthService = Depends(get_auth_service),
) -> AuthenticatedUser:
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "code": "UNAUTHORIZED",
                "message": "Silakan masuk terlebih dahulu.",
            },
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        return await auth_service.verify_access_token(credentials.credentials)
    except InvalidAccessTokenError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "UNAUTHORIZED", "message": str(exc)},
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc
    except AuthServiceUnavailableError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"code": "AUTH_UNAVAILABLE", "message": str(exc)},
        ) from exc
