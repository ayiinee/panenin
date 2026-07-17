from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any, Protocol
from uuid import uuid4

from whatsapp_service.agent_client import AgentApiError


class AgentPort(Protocol):
    async def link(self, subject: str, code: str) -> dict[str, Any]: ...
    async def context(self, subject: str) -> dict[str, Any]: ...
    async def inventory(self, subject: str) -> list[dict[str, Any]]: ...
    async def orders(self, subject: str) -> list[dict[str, Any]]: ...
    async def control_preview(
        self,
        subject: str,
        action: str,
        target_id: str,
        *,
        quantity: str | None = None,
        reason: str | None = None,
    ) -> dict[str, Any]: ...
    async def confirm(
        self,
        subject: str,
        action_id: str,
        code: str,
        idempotency_key: str,
    ) -> dict[str, Any]: ...
    async def cancel(self, subject: str, action_id: str) -> dict[str, Any]: ...


@dataclass
class ConversationState:
    inventory_aliases: dict[str, str] = field(default_factory=dict)
    order_aliases: dict[str, str] = field(default_factory=dict)
    pending_action_id: str | None = None


class ConversationEngine:
    def __init__(self, agent: AgentPort) -> None:
        self._agent = agent
        self._states: dict[str, ConversationState] = {}

    async def handle(self, subject: str, raw_message: str) -> str:
        message = " ".join(raw_message.strip().split())
        if not message:
            return self._menu()
        state = self._states.setdefault(subject, ConversationState())
        command = message.upper()
        try:
            if command in {"MENU", "BANTU", "HELP", "MULAI", "START"}:
                return self._menu()
            if match := re.fullmatch(r"HUBUNGKAN\s+([A-Z0-9]{6,12})", command):
                result = await self._agent.link(subject, match.group(1))
                name = result.get("organizationName", "akun Panenin")
                return (
                    f"✅ WhatsApp berhasil terhubung ke *{name}*.\n\n"
                    "Ketik *STATUS*, *STOK*, atau *PESANAN*."
                )
            if command == "STATUS":
                return self._format_context(await self._agent.context(subject))
            if command == "STOK":
                items = await self._agent.inventory(subject)
                state.inventory_aliases = {
                    str(index): str(item["id"])
                    for index, item in enumerate(items, start=1)
                }
                return self._format_inventory(items)
            if command == "PESANAN":
                items = await self._agent.orders(subject)
                state.order_aliases = {
                    str(index): str(item["id"])
                    for index, item in enumerate(items, start=1)
                }
                return self._format_orders(items)
            if match := re.fullmatch(
                r"(?:UBAH|ATUR)\s+STOK\s+(\S+)\s+([0-9]+(?:[.,][0-9]{1,3})?)",
                command,
            ):
                target_id = self._resolve_target(
                    match.group(1),
                    state.inventory_aliases,
                    "stok",
                )
                return await self._preview(
                    state,
                    subject,
                    "ADJUST_INVENTORY",
                    target_id,
                    quantity=match.group(2).replace(",", "."),
                )
            order_match = re.fullmatch(
                r"(TERIMA|TOLAK|SIAP|BATAL|SELESAI)\s+(?:PESANAN\s+)?(\S+)",
                command,
            )
            if order_match:
                action = {
                    "TERIMA": "ACCEPT_ORDER",
                    "TOLAK": "REJECT_ORDER",
                    "SIAP": "MARK_ORDER_READY",
                    "BATAL": "CANCEL_ORDER",
                    "SELESAI": "COMPLETE_ORDER",
                }[order_match.group(1)]
                target_id = self._resolve_target(
                    order_match.group(2),
                    state.order_aliases,
                    "pesanan",
                )
                return await self._preview(state, subject, action, target_id)
            if match := re.fullmatch(r"KONFIRMASI\s+([A-Z0-9]{6,12})", command):
                if state.pending_action_id is None:
                    return "Tidak ada aksi yang menunggu konfirmasi."
                result = await self._agent.confirm(
                    subject,
                    state.pending_action_id,
                    match.group(1),
                    str(uuid4()),
                )
                state.pending_action_id = None
                return self._format_result(result)
            if command in {"BATALKAN", "BATALKAN AKSI"}:
                if state.pending_action_id is None:
                    return "Tidak ada aksi yang menunggu pembatalan."
                await self._agent.cancel(subject, state.pending_action_id)
                state.pending_action_id = None
                return "✅ Aksi dibatalkan. Tidak ada data yang diubah."
            return (
                "Saya belum mengenali perintah itu.\n\n"
                "Ketik *MENU* untuk melihat perintah yang tersedia."
            )
        except AgentApiError as exc:
            if exc.code in {"FORBIDDEN", "NOT_FOUND"} and "terhubung" in exc.message:
                return (
                    "Akun ini belum terhubung.\n"
                    "Buat kode di aplikasi Panenin, lalu kirim:\n"
                    "*HUBUNGKAN KODE*"
                )
            return f"⚠️ {exc.message}\nKode: {exc.code}"
        except ValueError as exc:
            return f"⚠️ {exc}"

    async def _preview(
        self,
        state: ConversationState,
        subject: str,
        action: str,
        target_id: str,
        *,
        quantity: str | None = None,
    ) -> str:
        preview = await self._agent.control_preview(
            subject,
            action,
            target_id,
            quantity=quantity,
        )
        state.pending_action_id = str(preview["actionId"])
        summary = preview.get("summary", {})
        readable = {
            "ACCEPT_ORDER": "terima pesanan",
            "REJECT_ORDER": "tolak pesanan",
            "MARK_ORDER_READY": "tandai pesanan siap",
            "CANCEL_ORDER": "batalkan pesanan",
            "COMPLETE_ORDER": "selesaikan pesanan",
            "ADJUST_INVENTORY": "ubah stok",
        }[action]
        details = self._summary_lines(summary)
        return (
            f"Konfirmasi aksi *{readable}*:\n"
            f"{details}\n\n"
            f"Kirim *KONFIRMASI {preview['confirmationCode']}* untuk menjalankan.\n"
            "Kirim *BATALKAN* untuk membatalkan."
        )

    @staticmethod
    def _resolve_target(value: str, aliases: dict[str, str], label: str) -> str:
        if value in aliases:
            return aliases[value]
        if re.fullmatch(
            r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-"
            r"[0-9a-fA-F]{4}-[0-9a-fA-F]{12}",
            value,
        ):
            return value
        if not aliases:
            raise ValueError(f"Ketik {label.upper()} dulu untuk melihat nomor {label}.")
        raise ValueError(f"Nomor {label} tidak ditemukan.")

    @staticmethod
    def _format_context(data: dict[str, Any]) -> str:
        identity = data["identity"]
        return (
            f"📊 *{identity['organizationName']}*\n"
            f"Tipe: {identity['organizationType']}\n"
            f"Stok: {data['inventorySummary']['availableQuantity']} "
            f"({data['inventorySummary']['batchCount']} batch)\n"
            f"Listing aktif: {data['listingSummary']['published']}\n"
            f"Permintaan terbuka: {data['demandSummary']['open']}\n"
            f"Pesanan aktif: {data['orderSummary']['active']}"
        )

    @staticmethod
    def _format_inventory(items: list[dict[str, Any]]) -> str:
        if not items:
            return "Belum ada stok."
        lines = ["📦 *Stok tersedia*"]
        for index, item in enumerate(items, start=1):
            grade = f", grade {item['grade']}" if item.get("grade") else ""
            lines.append(
                f"{index}. {item['commodity']}: "
                f"{item['quantityAvailable']} {item['unit']}{grade}"
            )
        lines.append("\nUbah stok: *UBAH STOK <nomor> <jumlah>*")
        return "\n".join(lines)

    @staticmethod
    def _format_orders(items: list[dict[str, Any]]) -> str:
        if not items:
            return "Belum ada pesanan."
        lines = ["🧾 *Pesanan*"]
        for index, item in enumerate(items, start=1):
            lines.append(
                f"{index}. {item['orderNumber']} — {item['commodity']} "
                f"{item['quantity']} {item['unit']} [{item['status']}]"
            )
        lines.append(
            "\nKontrol: *TERIMA 1*, *TOLAK 1*, *SIAP 1*, *BATAL 1*, atau *SELESAI 1*"
        )
        return "\n".join(lines)

    @staticmethod
    def _summary_lines(summary: dict[str, Any]) -> str:
        labels = {
            "orderNumber": "Pesanan",
            "commodity": "Komoditas",
            "currentStatus": "Status sekarang",
            "quantityBefore": "Jumlah awal",
            "quantityAfter": "Jumlah baru",
        }
        return "\n".join(
            f"- {labels[key]}: {value}"
            for key, value in summary.items()
            if key in labels and value is not None
        )

    @staticmethod
    def _format_result(result: dict[str, Any]) -> str:
        if "orderNumber" in result:
            return (
                f"✅ Pesanan *{result['orderNumber']}* berhasil diperbarui "
                f"menjadi *{result['status']}*."
            )
        if "quantityAvailable" in result:
            return (
                "✅ Stok berhasil diperbarui menjadi "
                f"*{result['quantityAvailable']}* ({result['status']})."
            )
        return "✅ Aksi berhasil dijalankan."

    @staticmethod
    def _menu() -> str:
        return (
            "🌾 *Panenin Bot*\n\n"
            "• *HUBUNGKAN <kode>* — hubungkan akun\n"
            "• *STATUS* — ringkasan usaha\n"
            "• *STOK* — lihat stok\n"
            "• *UBAH STOK <nomor> <jumlah>* — koreksi stok\n"
            "• *PESANAN* — lihat pesanan\n"
            "• *TERIMA/TOLAK/SIAP/BATAL/SELESAI <nomor>* — kontrol pesanan\n"
            "• *KONFIRMASI <kode>* — jalankan aksi\n"
            "• *BATALKAN* — batalkan aksi tertunda"
        )

