import json
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal, ROUND_HALF_UP
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.agent_api.actions import ActionExecutor
from app.agent_api.schemas import (
    BuyPreviewRequest,
    CatalogSearchRequest,
    ConfirmActionRequest,
    ControlPreviewRequest,
    OrderPreviewRequest,
    PreviewResponse,
    SellPreviewRequest,
)
from app.core.config import get_settings
from app.core.errors import AuthorizationError, ConflictError, NotFoundError
from app.core.idempotency import canonical_payload_hash, normalize_idempotency_key
from app.core.security import (
    generate_confirmation_code,
    hash_one_time_code,
    verify_one_time_code,
)
from app.demands.service import DemandService
from app.inventory.service import InventoryService
from app.listings.repository import ListingRepository
from app.matching.service import MatchingService
from app.orders.repository import OrderRepository
from app.orders.service import OrderService
from app.organizations.models import OwnedOrganization
from app.organizations.repository import OrganizationRepository
from app.whatsapp.linking import WhatsAppLinkingService


class AgentService:
    def __init__(self) -> None:
        self._linking = WhatsAppLinkingService()
        self._organizations = OrganizationRepository()
        self._inventory = InventoryService()
        self._demands = DemandService()
        self._orders = OrderService()
        self._order_repository = OrderRepository()
        self._listings = ListingRepository()
        self._matching = MatchingService()
        self._executor = ActionExecutor()

    async def resolve_identity(self, session: AsyncSession, subject: str) -> dict:
        return await self._linking.resolve_identity(session, subject)

    async def link_identity(
        self,
        session: AsyncSession,
        *,
        subject: str,
        link_code: str,
        request_id: str,
    ) -> dict:
        return await self._linking.link_identity(
            session,
            channel_subject=subject,
            link_code=link_code,
            request_id=request_id,
        )

    async def context(self, session: AsyncSession, subject: str) -> dict:
        identity, user_id, organization = await self._require_identity(session, subject)
        inventory = await self._inventory.list_inventory(session, user_id)
        demands = await self._demands.list_demands(session, user_id)
        orders = await self._orders.list_orders(session, user_id)
        listings = await self._listings.list_for_organization(session, organization.id)
        pending = (
            await session.execute(
                text(
                    """
                    select id, intent, expires_at
                    from public.bot_actions
                    where user_id = :user_id and channel_subject = :subject
                      and confirmation_status = 'PENDING'
                      and execution_status = 'PENDING'
                      and expires_at > now()
                    order by created_at desc
                    limit 5
                    """
                ),
                {"user_id": user_id, "subject": subject},
            )
        ).mappings().all()
        return {
            "identity": {
                "organizationId": identity["organizationId"],
                "organizationType": identity["organizationType"],
                "organizationName": identity["organizationName"],
            },
            "inventorySummary": {
                "batchCount": len(inventory),
                "availableQuantity": str(
                    sum((item.quantity_available for item in inventory), Decimal("0"))
                ),
            },
            "listingSummary": {
                "total": len(listings),
                "published": sum(1 for item in listings if item["status"] == "PUBLISHED"),
            },
            "demandSummary": {
                "total": len(demands),
                "open": sum(1 for item in demands if item.status in {"OPEN", "PARTIALLY_MATCHED"}),
            },
            "orderSummary": {
                "total": len(orders),
                "active": sum(
                    1
                    for item in orders
                    if item.status not in {"COMPLETED", "REJECTED", "CANCELLED"}
                ),
            },
            "pendingActions": [
                {
                    "actionId": str(row["id"]),
                    "intent": row["intent"],
                    "expiresAt": row["expires_at"].isoformat(),
                }
                for row in pending
            ],
        }

    async def inventory(self, session: AsyncSession, subject: str) -> list[dict]:
        _, user_id, _ = await self._require_identity(session, subject)
        items = await self._inventory.list_inventory(session, user_id)
        return [
            {
                "id": str(item.id),
                "commodity": item.commodity,
                "quantityAvailable": str(item.quantity_available),
                "quantityReserved": str(item.quantity_reserved),
                "unit": item.unit,
                "grade": item.grade,
                "status": item.status,
                "availableAt": item.available_at.isoformat(),
            }
            for item in items
        ]

    async def demands(self, session: AsyncSession, subject: str) -> list[dict]:
        _, user_id, _ = await self._require_identity(session, subject)
        items = await self._demands.list_demands(session, user_id)
        return [
            {
                "id": str(item.id),
                "buyerOrganizationId": str(item.buyer_organization_id),
                "buyerName": item.buyer_name,
                "commodity": item.commodity,
                "quantityRemaining": str(item.quantity_remaining),
                "unit": item.unit,
                "maxPrice": str(item.max_price),
                "neededAt": item.needed_at.isoformat(),
                "status": item.status,
            }
            for item in items
        ]

    async def orders(self, session: AsyncSession, subject: str) -> list[dict]:
        _, user_id, _ = await self._require_identity(session, subject)
        items = await self._orders.list_orders(session, user_id)
        return [
            {
                "id": str(item.id),
                "orderNumber": item.order_number,
                "commodity": item.commodity,
                "quantity": str(item.quantity),
                "unit": item.unit,
                "totalAmount": str(item.total_amount),
                "status": item.status,
                "deliveryMethod": item.delivery_method,
                "deliveryDate": item.delivery_date.isoformat(),
            }
            for item in items
        ]

    async def catalog_search(
        self,
        session: AsyncSession,
        payload: CatalogSearchRequest,
    ) -> list[dict]:
        await self._require_identity(session, payload.channel_subject)
        return await self._matching.listing_candidates(
            session,
            commodity=payload.commodity,
            quantity=payload.quantity,
            unit=payload.unit,
            max_price=payload.max_price,
            needed_at=payload.needed_at,
            grade_tolerance=[],
        )

    async def sell_preview(
        self,
        session: AsyncSession,
        payload: SellPreviewRequest,
    ) -> PreviewResponse:
        async with session.begin():
            _, user_id, organization = await self._require_identity(
                session,
                payload.channel_subject,
            )
            if organization.type != "FARM":
                raise AuthorizationError("Hanya FARM dapat menjual hasil panen.")
            commodity = await self._resolve_commodity(
                session,
                payload.commodity,
                payload.unit,
            )
            candidates = await self._matching.demand_candidates(
                session,
                commodity=commodity["name"],
                quantity=payload.quantity,
                unit=commodity["default_unit"],
                listing_price=payload.listing_price,
                available_at=payload.available_at,
                grade=payload.grade,
                seller_organization_id=organization.id,
            )
            parameters = {
                "commodityId": str(commodity["id"]),
                "commodity": commodity["name"],
                "quantity": str(payload.quantity),
                "unit": commodity["default_unit"],
                "grade": payload.grade,
                "harvestedAt": payload.harvested_at.isoformat()
                if payload.harvested_at
                else None,
                "availableAt": payload.available_at.isoformat(),
                "minimumPrice": str(payload.minimum_price),
                "listingPrice": str(payload.listing_price),
                "minimumOrder": str(payload.minimum_order),
                "listingType": payload.listing_type,
            }
            return await self._create_preview(
                session,
                user_id=user_id,
                subject=payload.channel_subject,
                intent="SELL_HARVEST",
                parameters=parameters,
                summary={
                    "commodity": commodity["name"],
                    "quantity": str(payload.quantity),
                    "unit": commodity["default_unit"],
                    "listingPrice": str(payload.listing_price),
                    "listingType": payload.listing_type,
                },
                candidate_demands=candidates,
            )

    async def buy_preview(
        self,
        session: AsyncSession,
        payload: BuyPreviewRequest,
    ) -> PreviewResponse:
        async with session.begin():
            _, user_id, organization = await self._require_identity(
                session,
                payload.channel_subject,
            )
            if organization.type != "UMKM":
                raise AuthorizationError("Hanya UMKM dapat membuat permintaan.")
            commodity = await self._resolve_commodity(
                session,
                payload.commodity,
                payload.unit,
            )
            candidates = await self._matching.listing_candidates(
                session,
                commodity=commodity["name"],
                quantity=payload.quantity,
                unit=commodity["default_unit"],
                max_price=payload.max_price,
                needed_at=payload.needed_at,
                grade_tolerance=payload.grade_tolerance,
            )
            parameters = {
                "commodityId": str(commodity["id"]),
                "commodity": commodity["name"],
                "quantity": str(payload.quantity),
                "unit": commodity["default_unit"],
                "gradeTolerance": [grade.upper() for grade in payload.grade_tolerance],
                "maxPrice": str(payload.max_price),
                "neededAt": payload.needed_at.isoformat(),
                "deliveryMethod": payload.delivery_method,
            }
            return await self._create_preview(
                session,
                user_id=user_id,
                subject=payload.channel_subject,
                intent="CREATE_DEMAND",
                parameters=parameters,
                summary={
                    "commodity": commodity["name"],
                    "quantity": str(payload.quantity),
                    "unit": commodity["default_unit"],
                    "maxPrice": str(payload.max_price),
                    "neededAt": payload.needed_at.isoformat(),
                },
                candidate_listings=candidates,
            )

    async def order_preview(
        self,
        session: AsyncSession,
        payload: OrderPreviewRequest,
    ) -> PreviewResponse:
        async with session.begin():
            _, user_id, organization = await self._require_identity(
                session,
                payload.channel_subject,
            )
            if organization.type != "UMKM":
                raise AuthorizationError("Hanya UMKM dapat membuat pesanan.")
            listing = await self._listings.get_listing(
                session,
                payload.listing_id,
                for_update=True,
            )
            if listing is None or listing["status"] != "PUBLISHED":
                raise ConflictError("LISTING_UNAVAILABLE", "Listing tidak tersedia.")
            if listing["seller_organization_id"] == organization.id:
                raise ConflictError("SELF_ORDER", "Organisasi tidak dapat membeli listing sendiri.")
            if payload.quantity < Decimal(listing["minimum_order"]):
                raise ConflictError("MINIMUM_ORDER", "Jumlah di bawah minimum order.")
            if payload.quantity > Decimal(listing["quantity_remaining"]):
                raise ConflictError("INSUFFICIENT_STOCK", "Stok listing tidak mencukupi.")
            if payload.delivery_date < date.today():
                raise ConflictError("INVALID_DELIVERY_DATE", "Tanggal pengiriman sudah lewat.")
            if payload.demand_id:
                demand = await self._demands._repository.get_demand(
                    session,
                    payload.demand_id,
                    for_update=True,
                )
                if demand is None or demand["buyer_organization_id"] != organization.id:
                    raise AuthorizationError("Permintaan tidak dimiliki organisasi ini.")
                if demand["commodity_id"] != listing["commodity_id"] or demand["unit"] != listing["unit"]:
                    raise ConflictError("DEMAND_MISMATCH", "Permintaan tidak sesuai listing.")
            unit_price = Decimal(listing["price_per_unit"])
            subtotal = (payload.quantity * unit_price).quantize(
                Decimal("0.01"),
                rounding=ROUND_HALF_UP,
            )
            parameters = {
                "listingId": str(payload.listing_id),
                "demandId": str(payload.demand_id) if payload.demand_id else None,
                "quantity": str(payload.quantity),
                "deliveryMethod": payload.delivery_method,
                "deliveryDate": payload.delivery_date.isoformat(),
            }
            return await self._create_preview(
                session,
                user_id=user_id,
                subject=payload.channel_subject,
                intent="CREATE_ORDER",
                parameters=parameters,
                expected_version=listing["updated_at"].isoformat(),
                summary={
                    "listingId": str(payload.listing_id),
                    "commodity": listing["commodity"],
                    "quantity": str(payload.quantity),
                    "unit": listing["unit"],
                    "unitPrice": str(unit_price),
                    "subtotal": str(subtotal),
                    "deliveryFee": "0.00",
                    "totalAmount": str(subtotal),
                },
            )

    async def control_preview(
        self,
        session: AsyncSession,
        payload: ControlPreviewRequest,
    ) -> PreviewResponse:
        async with session.begin():
            _, user_id, organization = await self._require_identity(
                session,
                payload.channel_subject,
            )
            summary: dict[str, Any]
            expected_version: str | None
            if payload.action.endswith("ORDER") or payload.action == "MARK_ORDER_READY":
                order = await self._order_repository.get_order(
                    session,
                    payload.target_id,
                    for_update=True,
                )
                if order is None:
                    raise NotFoundError("Pesanan tidak ditemukan.")
                is_buyer = organization.id == order["buyer_organization_id"]
                is_seller = organization.id == order["seller_organization_id"]
                if not is_buyer and not is_seller:
                    raise AuthorizationError()
                if payload.action in {"ACCEPT_ORDER", "REJECT_ORDER", "MARK_ORDER_READY"} and not is_seller:
                    raise AuthorizationError("Aksi ini hanya tersedia untuk penjual.")
                if payload.action == "COMPLETE_ORDER" and not is_buyer:
                    raise AuthorizationError("Aksi ini hanya tersedia untuk pembeli.")
                summary = {
                    "action": payload.action,
                    "targetId": str(payload.target_id),
                    "orderNumber": order["order_number"],
                    "currentStatus": order["status"],
                }
                expected_version = order["updated_at"].isoformat()
            elif payload.action in {"PAUSE_LISTING", "PUBLISH_LISTING"}:
                listing = await self._listings.get_listing(
                    session,
                    payload.target_id,
                    for_update=True,
                )
                if listing is None:
                    raise NotFoundError("Listing tidak ditemukan.")
                if listing["seller_organization_id"] != organization.id or organization.type != "FARM":
                    raise AuthorizationError()
                summary = {
                    "action": payload.action,
                    "targetId": str(payload.target_id),
                    "commodity": listing["commodity"],
                    "currentStatus": listing["status"],
                }
                expected_version = listing["updated_at"].isoformat()
            else:
                batch = (
                    await session.execute(
                        text(
                            """
                            select b.id, b.organization_id, b.quantity_available,
                                   b.updated_at, c.name as commodity
                            from public.inventory_batches b
                            join public.commodities c on c.id = b.commodity_id
                            where b.id = :id for update of b
                            """
                        ),
                        {"id": payload.target_id},
                    )
                ).mappings().first()
                if batch is None:
                    raise NotFoundError("Batch stok tidak ditemukan.")
                if batch["organization_id"] != organization.id or organization.type != "FARM":
                    raise AuthorizationError()
                summary = {
                    "action": payload.action,
                    "targetId": str(payload.target_id),
                    "commodity": batch["commodity"],
                    "quantityBefore": str(batch["quantity_available"]),
                    "quantityAfter": str(payload.quantity),
                }
                expected_version = batch["updated_at"].isoformat()
            parameters = {
                "targetId": str(payload.target_id),
                "reason": payload.reason,
                "quantity": str(payload.quantity) if payload.quantity is not None else None,
            }
            return await self._create_preview(
                session,
                user_id=user_id,
                subject=payload.channel_subject,
                intent=payload.action,
                parameters=parameters,
                expected_version=expected_version,
                summary=summary,
            )

    async def confirm_action(
        self,
        session: AsyncSession,
        action_id: UUID,
        payload: ConfirmActionRequest,
        *,
        request_id: str,
    ) -> dict:
        try:
            idempotency_key = normalize_idempotency_key(payload.idempotency_key)
        except ValueError as exc:
            raise ConflictError("INVALID_IDEMPOTENCY_KEY", "Idempotency key tidak valid.") from exc
        async with session.begin():
            action = (
                await session.execute(
                    text("select * from public.bot_actions where id = :id for update"),
                    {"id": action_id},
                )
            ).mappings().first()
            if action is None:
                raise NotFoundError("Aksi tidak ditemukan.")
            identity, user_id, organization = await self._require_identity(
                session,
                payload.channel_subject,
            )
            del identity
            if action["user_id"] != user_id or action["channel_subject"] != payload.channel_subject:
                raise AuthorizationError("Aksi tidak dimiliki identitas ini.")
            if action["execution_status"] == "COMPLETED":
                if action["idempotency_key"] != idempotency_key:
                    raise ConflictError("IDEMPOTENCY_CONFLICT", "Aksi sudah diproses dengan key lain.")
                return dict(action["result_json"] or {})
            if action["confirmation_status"] != "PENDING" or action["execution_status"] != "PENDING":
                raise ConflictError("ACTION_NOT_PENDING", "Aksi tidak lagi menunggu konfirmasi.")
            if action["expires_at"] is None or action["expires_at"] <= datetime.now(UTC):
                await session.execute(
                    text(
                        "update public.bot_actions set confirmation_status = 'EXPIRED' where id = :id"
                    ),
                    {"id": action_id},
                )
                raise ConflictError("ACTION_EXPIRED", "Aksi sudah kedaluwarsa.")
            pepper = get_settings().confirmation_code_pepper.get_secret_value()
            if not action["confirmation_code_hash"] or not verify_one_time_code(
                payload.confirmation_code,
                action["confirmation_code_hash"],
                pepper,
            ):
                raise ConflictError("INVALID_CONFIRMATION_CODE", "Kode konfirmasi tidak valid.")
            parameters = dict(action["parameters_json"])
            if canonical_payload_hash(parameters) != action["payload_hash"]:
                raise ConflictError("ACTION_PAYLOAD_CHANGED", "Payload aksi tidak valid.")
            duplicate_key = (
                await session.execute(
                    text(
                        "select id from public.bot_actions where idempotency_key = :key and id <> :id"
                    ),
                    {"key": idempotency_key, "id": action_id},
                )
            ).scalar_one_or_none()
            if duplicate_key is not None:
                raise ConflictError("IDEMPOTENCY_CONFLICT", "Idempotency key sudah digunakan.")
            await session.execute(
                text(
                    """
                    update public.bot_actions
                    set idempotency_key = :key, execution_status = 'PROCESSING'
                    where id = :id
                    """
                ),
                {"key": idempotency_key, "id": action_id},
            )
            result = await self._executor.execute(
                session,
                intent=action["intent"],
                parameters=parameters,
                actor_user_id=user_id,
                organization=organization,
                idempotency_key=idempotency_key,
                request_id=request_id,
            )
            await session.execute(
                text(
                    """
                    update public.bot_actions
                    set confirmation_status = 'CONFIRMED',
                        execution_status = 'COMPLETED', confirmed_at = now(),
                        result_json = cast(:result as jsonb), error_message = null
                    where id = :id
                    """
                ),
                {
                    "result": json.dumps(result, separators=(",", ":")),
                    "id": action_id,
                },
            )
            await session.execute(
                text(
                    """
                    insert into public.audit_logs (
                      actor_user_id, action, entity_type, entity_id,
                      source, new_data_json, request_id
                    ) values (
                      :user_id, 'CONFIRM_BOT_ACTION', 'bot_action', :action_id,
                      'WHATSAPP', cast(:data as jsonb), :request_id
                    )
                    """
                ),
                {
                    "user_id": user_id,
                    "action_id": action_id,
                    "data": json.dumps({"intent": action["intent"]}),
                    "request_id": request_id,
                },
            )
            return result

    async def cancel_action(
        self,
        session: AsyncSession,
        action_id: UUID,
        subject: str,
        *,
        request_id: str,
    ) -> dict:
        async with session.begin():
            action = (
                await session.execute(
                    text("select * from public.bot_actions where id = :id for update"),
                    {"id": action_id},
                )
            ).mappings().first()
            if action is None:
                raise NotFoundError("Aksi tidak ditemukan.")
            _, user_id, _ = await self._require_identity(session, subject)
            if action["user_id"] != user_id or action["channel_subject"] != subject:
                raise AuthorizationError("Aksi tidak dimiliki identitas ini.")
            if action["confirmation_status"] != "PENDING" or action["execution_status"] != "PENDING":
                raise ConflictError("ACTION_NOT_PENDING", "Aksi tidak dapat dibatalkan.")
            await session.execute(
                text(
                    """
                    update public.bot_actions
                    set confirmation_status = 'REJECTED', cancelled_at = now()
                    where id = :id
                    """
                ),
                {"id": action_id},
            )
            await session.execute(
                text(
                    """
                    insert into public.audit_logs (
                      actor_user_id, action, entity_type, entity_id,
                      source, new_data_json, request_id
                    ) values (
                      :user_id, 'CANCEL_BOT_ACTION', 'bot_action', :action_id,
                      'WHATSAPP', cast(:data as jsonb), :request_id
                    )
                    """
                ),
                {
                    "user_id": user_id,
                    "action_id": action_id,
                    "data": json.dumps({"intent": action["intent"]}),
                    "request_id": request_id,
                },
            )
        return {"actionId": str(action_id), "status": "CANCELLED"}

    async def _create_preview(
        self,
        session: AsyncSession,
        *,
        user_id: UUID,
        subject: str,
        intent: str,
        parameters: dict[str, Any],
        summary: dict[str, Any],
        expected_version: str | None = None,
        candidate_demands: list[dict] | None = None,
        candidate_listings: list[dict] | None = None,
    ) -> PreviewResponse:
        if intent not in self._executor.allowed_intents:
            raise ConflictError("UNKNOWN_ACTION", "Aksi tidak dikenali.")
        settings = get_settings()
        code = generate_confirmation_code()
        code_hash = hash_one_time_code(
            code,
            settings.confirmation_code_pepper.get_secret_value(),
        )
        action_id = uuid4()
        expires_at = datetime.now(UTC) + timedelta(seconds=settings.bot_action_ttl_seconds)
        payload_hash = canonical_payload_hash(parameters)
        await session.execute(
            text(
                """
                insert into public.bot_actions (
                  id, user_id, intent, parameters_json, risk_level,
                  confirmation_status, execution_status, idempotency_key,
                  confirmation_code_hash, expires_at, expected_version,
                  channel_subject, payload_hash
                ) values (
                  :id, :user_id, :intent, cast(:parameters as jsonb), 'MEDIUM',
                  'PENDING', 'PENDING', :preview_key,
                  :code_hash, :expires_at, :expected_version,
                  :subject, :payload_hash
                )
                """
            ),
            {
                "id": action_id,
                "user_id": user_id,
                "intent": intent,
                "parameters": json.dumps(parameters, separators=(",", ":")),
                "preview_key": f"preview:{action_id}",
                "code_hash": code_hash,
                "expires_at": expires_at,
                "expected_version": expected_version,
                "subject": subject,
                "payload_hash": payload_hash,
            },
        )
        return PreviewResponse(
            action_id=action_id,
            confirmation_code=code,
            expires_at=expires_at,
            summary=summary,
            candidate_demands=candidate_demands,
            candidate_listings=candidate_listings,
        )

    async def _require_identity(
        self,
        session: AsyncSession,
        subject: str,
    ) -> tuple[dict, UUID, OwnedOrganization]:
        identity = await self._linking.resolve_identity(session, subject)
        if not identity.get("linked"):
            raise AuthorizationError("Identitas WhatsApp belum terhubung.")
        user_id = UUID(identity["userId"])
        organization = await self._organizations.get_owned_organization(session, user_id)
        if organization is None or str(organization.id) != identity["organizationId"]:
            raise AuthorizationError("Organisasi tidak aktif.")
        return identity, user_id, organization

    async def _resolve_commodity(
        self,
        session: AsyncSession,
        name: str,
        unit: str,
    ) -> dict:
        row = (
            await session.execute(
                text(
                    """
                    select id, name, default_unit from public.commodities
                    where is_active and lower(name) = lower(:name)
                    """
                ),
                {"name": name},
            )
        ).mappings().first()
        if row is None:
            raise NotFoundError("Komoditas tidak ditemukan.")
        if row["default_unit"].casefold() != unit.casefold():
            raise ConflictError("UNIT_MISMATCH", "Satuan komoditas tidak sesuai.")
        return dict(row)
