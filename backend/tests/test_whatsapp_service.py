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


def test_gateway_diagnostics_do_not_expose_message_or_sender() -> None:
    from whatsapp_service import app as module

    with TestClient(module.app) as client:
        response = client.get("/health/diagnostics")

    assert response.status_code == 200
    assert set(response.json()["diagnostics"]) == {
        "started_at",
        "webhook_requests",
        "webhook_rejected",
        "messages_accepted",
        "messages_ignored",
        "replies_sent",
        "send_failures",
        "last_inbound_at",
        "last_reply_at",
        "last_error",
        "last_payload_keys",
        "last_auth_source",
        "last_rejected_payload_keys",
        "last_rejected_auth_source",
    }


def test_fonnte_webhook_accepts_secret_key_payload_alias(monkeypatch) -> None:
    from whatsapp_service import app as module

    captured: list[tuple[str, str]] = []

    async def fake_process(
        sender: str,
        message: str,
        inbox_id: str | None,
    ) -> None:
        del inbox_id
        captured.append((sender, message))

    monkeypatch.setattr(
        module.settings,
        "fonnte_webhook_secret",
        module.settings.fonnte_webhook_secret.__class__("configured"),
    )
    monkeypatch.setattr(module, "_process_and_reply", fake_process)
    with TestClient(module.app) as client:
        response = client.post(
            "/webhook/fonnte",
            json={
                "sender": "628123456789",
                "message": "MENU",
                "secret_key": "configured",
            },
        )

    assert response.status_code == 200
    assert captured == [("628123456789", "MENU")]
    assert module.diagnostics.last_auth_source == "payload.secret_key"
    assert module.diagnostics.last_payload_keys == [
        "message",
        "secret_key",
        "sender",
    ]


def test_fonnte_webhook_accepts_derived_path_token(monkeypatch) -> None:
    from whatsapp_service import app as module

    captured: list[tuple[str, str]] = []

    async def fake_process(
        sender: str,
        message: str,
        inbox_id: str | None,
    ) -> None:
        del inbox_id
        captured.append((sender, message))

    monkeypatch.setattr(
        module.settings,
        "fonnte_webhook_secret",
        module.settings.fonnte_webhook_secret.__class__("configured"),
    )
    monkeypatch.setattr(module, "_process_and_reply", fake_process)
    path_token = hashlib.sha256(b"configured").hexdigest()
    with TestClient(module.app) as client:
        response = client.post(
            f"/webhook/fonnte/{path_token}",
            json={"sender": "628123456789", "message": "MENU"},
        )

    assert response.status_code == 200
    assert captured == [("628123456789", "MENU")]
    assert module.diagnostics.last_auth_source == "path"


def test_fonnte_webhook_accepts_non_numeric_inbox_without_forwarding_it(
    monkeypatch,
) -> None:
    from whatsapp_service import app as module

    captured: list[str | None] = []

    async def fake_process(
        sender: str,
        message: str,
        inbox_id: str | None,
    ) -> None:
        del sender, message
        captured.append(inbox_id)

    monkeypatch.setattr(
        module.settings,
        "fonnte_webhook_secret",
        module.settings.fonnte_webhook_secret.__class__("configured"),
    )
    monkeypatch.setattr(module, "_process_and_reply", fake_process)
    with TestClient(module.app) as client:
        response = client.post(
            "/webhook/fonnte?secret=configured",
            json={
                "sender": "628123456789",
                "message": "MENU",
                "inboxid": "not-numeric",
            },
        )

    assert response.status_code == 200
    assert captured == [None]
