import hashlib

import pytest
from fastapi.security import HTTPAuthorizationCredentials
from pydantic import SecretStr

from app.agent_api.actions import ActionExecutor
from app.agent_api.security import require_agent_service
from app.core.config import Settings
from app.core.errors import AuthenticationError
from app.core.security import (
    generate_confirmation_code,
    hash_one_time_code,
    verify_one_time_code,
)


@pytest.mark.asyncio
async def test_service_token_accepts_matching_hash() -> None:
    token = "test-service-token"
    settings = Settings(
        panenin_ai_service_token_hash=SecretStr(
            hashlib.sha256(token.encode()).hexdigest()
        )
    )
    credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)

    assert await require_agent_service(credentials, settings) is None


@pytest.mark.asyncio
async def test_service_token_rejects_invalid_and_empty_tokens() -> None:
    settings = Settings(
        panenin_ai_service_token_hash=SecretStr(hashlib.sha256(b"valid").hexdigest())
    )
    with pytest.raises(AuthenticationError):
        await require_agent_service(
            HTTPAuthorizationCredentials(scheme="Bearer", credentials="invalid"),
            settings,
        )
    with pytest.raises(AuthenticationError):
        await require_agent_service(None, settings)


def test_confirmation_code_is_hashed_and_constant_time_verified() -> None:
    code = generate_confirmation_code()
    digest = hash_one_time_code(code, "test-pepper")

    assert code not in digest
    assert len(digest) == 64
    assert verify_one_time_code(code, digest, "test-pepper")
    assert not verify_one_time_code("AAAAAA", digest, "test-pepper")


def test_action_registry_is_closed() -> None:
    assert ActionExecutor().allowed_intents == {
        "SELL_HARVEST",
        "CREATE_DEMAND",
        "CREATE_ORDER",
        "ACCEPT_ORDER",
        "REJECT_ORDER",
        "MARK_ORDER_READY",
        "CANCEL_ORDER",
        "COMPLETE_ORDER",
        "PAUSE_LISTING",
        "PUBLISH_LISTING",
        "ADJUST_INVENTORY",
    }
