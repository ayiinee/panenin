import hashlib

import httpx
import pytest
from fastapi.testclient import TestClient

from whatsapp_service.agent_client import PaneninAgentClient
from whatsapp_service.config import WhatsAppSettings
from whatsapp_service.demo_agent import DemoAgentClient
from whatsapp_service.engine import ConversationEngine
from whatsapp_service.security import derive_channel_subject


def test_channel_subject_is_opaque_and_stable() -> None:
    first = derive_channel_subject("628123456789", "pepper")
    second = derive_channel_subject("628123456789", "pepper")

    assert first == second
    assert first.startswith("wa:v1:")
    assert "628123456789" not in first
    assert len(first.removeprefix("wa:v1:")) == hashlib.sha256().digest_size * 2


@pytest.mark.asyncio
async def test_demo_remote_control_requires_confirmation() -> None:
    agent = DemoAgentClient()
    engine = ConversationEngine(agent)
    subject = derive_channel_subject("demo-session", "demo-pepper")

    assert "berhasil terhubung" in await engine.handle(subject, "HUBUNGKAN DEMO12")
    before = await engine.handle(subject, "STOK")
    assert "40 kg" in before
    preview = await engine.handle(subject, "UBAH STOK 1 32")
    assert "KONFIRMASI 123456" in preview
    assert "40 kg" in await engine.handle(subject, "STOK")
    confirmed = await engine.handle(subject, "KONFIRMASI 123456")
    assert "32" in confirmed
    assert "32 kg" in await engine.handle(subject, "STOK")


@pytest.mark.asyncio
async def test_agent_client_uses_bearer_and_unwraps_envelope() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.headers["Authorization"] == "Bearer service-token"
        assert request.url.params["channelSubject"].startswith("wa:v1:")
        return httpx.Response(
            200,
            json={"data": {"orderSummary": {"active": 1}}, "error": None},
        )

    settings = WhatsAppSettings(
        panenin_core_api_url="https://core.example",
        panenin_ai_service_token="service-token",
    )
    async with httpx.AsyncClient(
        base_url="https://core.example",
        transport=httpx.MockTransport(handler),
    ) as client:
        result = await PaneninAgentClient(settings, client).context(
            f"wa:v1:{'a' * 64}"
        )

    assert result["orderSummary"]["active"] == 1


def test_fonnte_webhook_rejects_missing_secret(monkeypatch) -> None:
    from whatsapp_service import app as module

    monkeypatch.setattr(
        module.settings,
        "fonnte_webhook_secret",
        module.settings.fonnte_webhook_secret.__class__("configured"),
    )
    with TestClient(module.app) as client:
        response = client.post(
            "/webhook/fonnte",
            json={"sender": "628123456789", "message": "MENU"},
        )

    assert response.status_code == 401
