from __future__ import annotations

import re
from copy import deepcopy
from typing import Any
from uuid import uuid4

from whatsapp_service.agent_client import AgentApiError


class DemoAgentClient:
    """In-memory contract double used only by the browser demo."""

    def __init__(self) -> None:
        self._linked: set[str] = set()
        self._inventory = [
            {
                "id": "00000000-0000-4000-8000-000000000101",
                "commodity": "Cabai Merah",
                "quantityAvailable": "40",
                "quantityReserved": "5",
                "unit": "kg",
                "grade": "A",
                "status": "AVAILABLE",
                "availableAt": "2026-07-17T08:00:00+07:00",
            },
            {
                "id": "00000000-0000-4000-8000-000000000102",
                "commodity": "Tomat",
                "quantityAvailable": "25",
                "quantityReserved": "0",
                "unit": "kg",
                "grade": "B",
                "status": "AVAILABLE",
                "availableAt": "2026-07-17T08:00:00+07:00",
            },
        ]
        self._orders = [
            {
                "id": "00000000-0000-4000-8000-000000000201",
                "orderNumber": "PNN-DEMO-001",
                "commodity": "Cabai Merah",
                "quantity": "5",
                "unit": "kg",
                "totalAmount": "247500",
                "status": "PENDING",
                "deliveryMethod": "PICKUP",
                "deliveryDate": "2026-07-18",
            },
            {
                "id": "00000000-0000-4000-8000-000000000202",
                "orderNumber": "PNN-DEMO-002",
                "commodity": "Tomat",
                "quantity": "10",
                "unit": "kg",
                "totalAmount": "180000",
                "status": "CONFIRMED",
                "deliveryMethod": "SELLER_DELIVERY",
                "deliveryDate": "2026-07-19",
            },
        ]
        self._actions: dict[str, dict[str, str]] = {}

    async def link(self, subject: str, code: str) -> dict[str, Any]:
        if not re.fullmatch(r"[A-Za-z0-9]{6,12}", code):
            raise AgentApiError("INVALID_LINK_CODE", "Kode penghubung tidak valid.", 409)
        self._linked.add(subject)
        return {
            "linked": True,
            "organizationType": "FARM",
            "organizationName": "Tani Makmur Demo",
        }

    async def context(self, subject: str) -> dict[str, Any]:
        self._require_linked(subject)
        return {
            "identity": {
                "organizationType": "FARM",
                "organizationName": "Tani Makmur Demo",
            },
            "inventorySummary": {
                "batchCount": len(self._inventory),
                "availableQuantity": str(
                    sum(float(item["quantityAvailable"]) for item in self._inventory)
                ),
            },
            "listingSummary": {"total": 2, "published": 1},
            "demandSummary": {"total": 3, "open": 2},
            "orderSummary": {
                "total": len(self._orders),
                "active": sum(
                    item["status"] not in {"COMPLETED", "REJECTED", "CANCELLED"}
                    for item in self._orders
                ),
            },
            "pendingActions": [],
        }

    async def inventory(self, subject: str) -> list[dict[str, Any]]:
        self._require_linked(subject)
        return deepcopy(self._inventory)

    async def orders(self, subject: str) -> list[dict[str, Any]]:
        self._require_linked(subject)
        return deepcopy(self._orders)

    async def control_preview(
        self,
        subject: str,
        action: str,
        target_id: str,
        *,
        quantity: str | None = None,
        reason: str | None = None,
    ) -> dict[str, Any]:
        del reason
        self._require_linked(subject)
        if action == "ADJUST_INVENTORY":
            item = next((row for row in self._inventory if row["id"] == target_id), None)
            if item is None:
                raise AgentApiError("NOT_FOUND", "Batch stok tidak ditemukan.", 404)
            summary = {
                "action": action,
                "commodity": item["commodity"],
                "quantityBefore": item["quantityAvailable"],
                "quantityAfter": quantity,
            }
        else:
            order = next((row for row in self._orders if row["id"] == target_id), None)
            if order is None:
                raise AgentApiError("NOT_FOUND", "Pesanan tidak ditemukan.", 404)
            summary = {
                "action": action,
                "orderNumber": order["orderNumber"],
                "currentStatus": order["status"],
            }
        action_id = str(uuid4())
        self._actions[action_id] = {
            "subject": subject,
            "action": action,
            "targetId": target_id,
            "quantity": quantity or "",
            "code": "123456",
        }
        return {
            "actionId": action_id,
            "confirmationCode": "123456",
            "expiresAt": "2026-12-31T23:59:59+07:00",
            "summary": summary,
        }

    async def confirm(
        self,
        subject: str,
        action_id: str,
        code: str,
        idempotency_key: str,
    ) -> dict[str, Any]:
        del idempotency_key
        action = self._actions.get(action_id)
        if action is None or action["subject"] != subject:
            raise AgentApiError("NOT_FOUND", "Aksi tidak ditemukan.", 404)
        if code != action["code"]:
            raise AgentApiError(
                "INVALID_CONFIRMATION_CODE",
                "Kode konfirmasi tidak valid.",
                409,
            )
        if action["action"] == "ADJUST_INVENTORY":
            item = next(row for row in self._inventory if row["id"] == action["targetId"])
            item["quantityAvailable"] = action["quantity"]
            item["status"] = (
                "SOLD_OUT" if float(action["quantity"]) == 0 else "AVAILABLE"
            )
            result = {
                "inventoryBatchId": item["id"],
                "quantityAvailable": item["quantityAvailable"],
                "status": item["status"],
            }
        else:
            order = next(row for row in self._orders if row["id"] == action["targetId"])
            next_status = {
                "ACCEPT_ORDER": "CONFIRMED",
                "REJECT_ORDER": "REJECTED",
                "MARK_ORDER_READY": "READY",
                "CANCEL_ORDER": "CANCELLED",
                "COMPLETE_ORDER": "COMPLETED",
            }[action["action"]]
            order["status"] = next_status
            result = {
                "orderId": order["id"],
                "orderNumber": order["orderNumber"],
                "status": next_status,
            }
        del self._actions[action_id]
        return result

    async def cancel(self, subject: str, action_id: str) -> dict[str, Any]:
        action = self._actions.get(action_id)
        if action is None or action["subject"] != subject:
            raise AgentApiError("NOT_FOUND", "Aksi tidak ditemukan.", 404)
        del self._actions[action_id]
        return {"actionId": action_id, "status": "CANCELLED"}

    def _require_linked(self, subject: str) -> None:
        if subject not in self._linked:
            raise AgentApiError(
                "FORBIDDEN",
                "Identitas WhatsApp belum terhubung.",
                403,
            )

