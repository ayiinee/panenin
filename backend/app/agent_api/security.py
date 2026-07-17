from typing import Annotated

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.config import Settings, get_settings
from app.core.errors import AuthenticationError
from app.core.security import verify_service_token

agent_bearer = HTTPBearer(auto_error=False)


async def require_agent_service(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(agent_bearer)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> None:
    token = credentials.credentials if credentials else ""
    configured_hash = settings.panenin_ai_service_token_hash.get_secret_value().strip()
    if not verify_service_token(token, configured_hash):
        raise AuthenticationError("Kredensial service tidak valid.")
