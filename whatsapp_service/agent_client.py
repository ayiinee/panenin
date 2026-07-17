from __future__ import annotations

from typing import Any

import httpx

from whatsapp_service.config import WhatsAppSettings


class AgentApiError(Exception):
    def __init__(self, code: str, message: str, status_code: int) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code


class PaneninAgentClient:
    def __init__(
        self,
        settings: WhatsAppSettings,
        client: httpx.AsyncClient | None = None,
    ) -> None:
        self._settings = settings
        self._client = client

    async def link(self, subject: str, code: str) -> dict[str, Any]:
        return await self._request(
            "POST",
            "/api/v1/internal/agent/identity/link",
            json={"channelSubject": subject, "linkCode": code},
        )

    async def context(self, subject: str) -> dict[str, Any]:
        return await self._request(
            "GET",
            "/api/v1/internal/agent/context",
            params={"channelSubject": subject},
        )

    async def inventory(self, subject: str) -> list[dict[str, Any]]:
        return await self._request(
            "GET",
            "/api/v1/internal/agent/inventory",
            params={"channelSubject": subject},
        )

    async def orders(self, subject: str) -> list[dict[str, Any]]:
        return await self._request(
            "GET",
            "/api/v1/internal/agent/orders",
            params={"channelSubject": subject},
        )

    async def control_preview(
        self,
        subject: str,
        action: str,
        target_id: str,
        *,
        quantity: str | None = None,
        reason: str | None = None,
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "channelSubject": subject,
            "action": action,
            "targetId": target_id,
        }
        if quantity is not None:
            payload["quantity"] = quantity
        if reason:
            payload["reason"] = reason
        return await self._request(
            "POST",
            "/api/v1/internal/agent/control/preview",
            json=payload,
        )

    async def confirm(
        self,
        subject: str,
        action_id: str,
        code: str,
        idempotency_key: str,
    ) -> dict[str, Any]:
        return await self._request(
            "POST",
            f"/api/v1/internal/agent/actions/{action_id}/confirm",
            json={
                "channelSubject": subject,
                "confirmationCode": code,
                "idempotencyKey": idempotency_key,
            },
        )

    async def cancel(self, subject: str, action_id: str) -> dict[str, Any]:
        return await self._request(
            "POST",
            f"/api/v1/internal/agent/actions/{action_id}/cancel",
            json={"channelSubject": subject},
        )

    async def _request(
        self,
        method: str,
        path: str,
        **kwargs: Any,
    ) -> Any:
        token = self._settings.panenin_ai_service_token.get_secret_value().strip()
        if not token:
            raise AgentApiError(
                "SERVICE_UNAVAILABLE",
                "Token service Panenin belum dikonfigurasi.",
                503,
            )
        headers = dict(kwargs.pop("headers", {}))
        headers["Authorization"] = f"Bearer {token}"
        owned_client = self._client is None
        client = self._client or httpx.AsyncClient(
            base_url=self._settings.panenin_core_api_url.rstrip("/"),
            timeout=httpx.Timeout(15.0, connect=5.0),
        )
        try:
            response = await client.request(method, path, headers=headers, **kwargs)
        except httpx.HTTPError as exc:
            raise AgentApiError(
                "CORE_UNAVAILABLE",
                "Panenin Core belum dapat dihubungi.",
                503,
            ) from exc
        finally:
            if owned_client:
                await client.aclose()
        try:
            envelope = response.json()
        except ValueError as exc:
            raise AgentApiError(
                "INVALID_CORE_RESPONSE",
                "Respons Panenin Core tidak valid.",
                502,
            ) from exc
        if response.is_error or envelope.get("error"):
            error = envelope.get("error") or {}
            raise AgentApiError(
                str(error.get("code", "CORE_ERROR")),
                str(error.get("message", "Permintaan ke Panenin Core gagal.")),
                response.status_code,
            )
        return envelope.get("data")

