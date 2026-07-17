import json
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Any, Awaitable, Callable
from uuid import UUID, uuid4

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import AuthorizationError, ConflictError, NotFoundError
from app.matching.service import MatchingService
from app.orders.schemas import OrderCreateCommand
from app.orders.service import OrderService
from app.organizations.models import OwnedOrganization

ActionHandler = Callable[..., Awaitable[dict[str, Any]]]


class ActionExecutor:
    def __init__(self) -> None:
        self._matching = MatchingService()
        self._orders = OrderService()
        self._handlers: dict[str, ActionHandler] = {
            "SELL_HARVEST": self._sell_harvest,
            "CREATE_DEMAND": self._create_demand,
            "CREATE_ORDER": self._create_order,
            "ACCEPT_ORDER": self._control_order,
            "REJECT_ORDER": self._control_order,
            "MARK_ORDER_READY": self._control_order,
            "CANCEL_ORDER": self._control_order,
            "COMPLETE_ORDER": self._control_order,
            "PAUSE_LISTING": self._control_listing,
            "PUBLISH_LISTING": self._control_listing,
            "ADJUST_INVENTORY": self._adjust_inventory,
        }

    @property
    def allowed_intents(self) -> frozenset[str]:
        return frozenset(self._handlers)

    async def execute(
        self,
        session: AsyncSession,
        *,
        intent: str,
        parameters: dict[str, Any],
        actor_user_id: UUID,
        organization: OwnedOrganization,
        idempotency_key: str,
        request_id: str,
    ) -> dict[str, Any]:
        handler = self._handlers.get(intent)
        if handler is None:
            raise ConflictError("UNKNOWN_ACTION", "Aksi tidak dikenali.")
        return await handler(
            session,
            intent=intent,
            parameters=parameters,
            actor_user_id=actor_user_id,
            organization=organization,
            idempotency_key=idempotency_key,
            request_id=request_id,
        )

    async def _sell_harvest(
        self,
        session: AsyncSession,
        *,
        parameters: dict[str, Any],
        actor_user_id: UUID,
        organization: OwnedOrganization,
        request_id: str,
        **_: Any,
    ) -> dict[str, Any]:
        if organization.type != "FARM":
            raise AuthorizationError("Hanya FARM dapat menjual hasil panen.")
        commodity = (
            await session.execute(
                text(
                    "select id, name, default_unit from public.commodities where id = :id and is_active"
                ),
                {"id": UUID(parameters["commodityId"])},
            )
        ).mappings().first()
        if commodity is None:
            raise NotFoundError("Komoditas tidak ditemukan.")
        quantity = Decimal(parameters["quantity"])
        minimum_price = Decimal(parameters["minimumPrice"])
        listing_price = Decimal(parameters["listingPrice"])
        minimum_order = Decimal(parameters["minimumOrder"])
        available_at = datetime.fromisoformat(parameters["availableAt"])
        harvested_at = (
            datetime.fromisoformat(parameters["harvestedAt"])
            if parameters.get("harvestedAt")
            else None
        )
        if listing_price < minimum_price or minimum_order > quantity:
            raise ConflictError("STALE_PREVIEW", "Parameter penjualan tidak lagi valid.")

        batch_id = uuid4()
        listing_id = uuid4()
        await session.execute(
            text(
                """
                insert into public.inventory_batches (
                  id, organization_id, commodity_id, quantity_total,
                  quantity_available, unit, grade, harvested_at,
                  available_at, minimum_price, status
                ) values (
                  :id, :organization_id, :commodity_id, :quantity,
                  :quantity, :unit, :grade, :harvested_at,
                  :available_at, :minimum_price, 'AVAILABLE'
                )
                """
            ),
            {
                "id": batch_id,
                "organization_id": organization.id,
                "commodity_id": commodity["id"],
                "quantity": quantity,
                "unit": commodity["default_unit"],
                "grade": parameters.get("grade"),
                "harvested_at": harvested_at,
                "available_at": available_at,
                "minimum_price": minimum_price,
            },
        )
        await session.execute(
            text(
                """
                insert into public.inventory_movements (
                  inventory_batch_id, movement_type, quantity,
                  quantity_before, quantity_after, actor_user_id, notes
                ) values (
                  :batch_id, 'STOCK_IN', :quantity, 0, :quantity,
                  :actor_user_id, 'Confirmed WhatsApp SELL_HARVEST action'
                )
                """
            ),
            {"batch_id": batch_id, "quantity": quantity, "actor_user_id": actor_user_id},
        )
        listing_type = parameters["listingType"]
        expires_at = available_at + timedelta(days=1) if listing_type == "RESCUE" else None
        await session.execute(
            text(
                """
                insert into public.listings (
                  id, inventory_batch_id, listing_type, price_per_unit,
                  minimum_order, source, status, quantity_listed,
                  quantity_remaining, unit, published_at, expires_at
                ) values (
                  :id, :batch_id, :listing_type, :price,
                  :minimum_order, 'WHATSAPP', 'PUBLISHED', :quantity,
                  :quantity, :unit, now(), :expires_at
                )
                """
            ),
            {
                "id": listing_id,
                "batch_id": batch_id,
                "listing_type": listing_type,
                "price": listing_price,
                "minimum_order": minimum_order,
                "quantity": quantity,
                "unit": commodity["default_unit"],
                "expires_at": expires_at,
            },
        )
        listing = {
            "id": listing_id,
            "seller_organization_id": organization.id,
            "commodity": commodity["name"],
            "quantity_remaining": quantity,
            "unit": commodity["default_unit"],
            "price_per_unit": listing_price,
            "available_at": available_at,
            "grade": parameters.get("grade"),
        }
        await self._matching.persist_for_listing(session, listing)
        await self._audit(
            session,
            actor_user_id=actor_user_id,
            action="SELL_HARVEST",
            entity_type="listing",
            entity_id=listing_id,
            request_id=request_id,
            data={"inventoryBatchId": str(batch_id), "quantity": str(quantity)},
        )
        return {
            "inventoryBatchId": str(batch_id),
            "listingId": str(listing_id),
            "status": "PUBLISHED",
            "quantity": str(quantity),
            "unit": commodity["default_unit"],
        }

    async def _create_demand(
        self,
        session: AsyncSession,
        *,
        parameters: dict[str, Any],
        actor_user_id: UUID,
        organization: OwnedOrganization,
        request_id: str,
        **_: Any,
    ) -> dict[str, Any]:
        if organization.type != "UMKM":
            raise AuthorizationError("Hanya UMKM dapat membuat permintaan.")
        commodity = (
            await session.execute(
                text(
                    "select id, name, default_unit from public.commodities where id = :id and is_active"
                ),
                {"id": UUID(parameters["commodityId"])},
            )
        ).mappings().first()
        if commodity is None:
            raise NotFoundError("Komoditas tidak ditemukan.")
        demand_id = uuid4()
        quantity = Decimal(parameters["quantity"])
        row = (
            await session.execute(
                text(
                    """
                    insert into public.demands (
                      id, buyer_organization_id, commodity_id, quantity,
                      quantity_remaining, unit, grade_tolerance, max_price,
                      needed_at, delivery_address_text, delivery_latitude,
                      delivery_longitude, status, source
                    ) values (
                      :id, :organization_id, :commodity_id, :quantity,
                      :quantity, :unit, :grades, :max_price, :needed_at,
                      :address, :latitude, :longitude, 'OPEN', 'WHATSAPP'
                    ) returning *
                    """
                ),
                {
                    "id": demand_id,
                    "organization_id": organization.id,
                    "commodity_id": commodity["id"],
                    "quantity": quantity,
                    "unit": commodity["default_unit"],
                    "grades": parameters.get("gradeTolerance", []),
                    "max_price": Decimal(parameters["maxPrice"]),
                    "needed_at": datetime.fromisoformat(parameters["neededAt"]),
                    "address": organization.address_text,
                    "latitude": organization.latitude,
                    "longitude": organization.longitude,
                },
            )
        ).mappings().one()
        demand = {
            **dict(row),
            "commodity": commodity["name"],
            "buyer_name": organization.name,
        }
        await self._matching.persist_for_demand(session, demand)
        await self._audit(
            session,
            actor_user_id=actor_user_id,
            action="CREATE_DEMAND",
            entity_type="demand",
            entity_id=demand_id,
            request_id=request_id,
            data={"commodityId": str(commodity["id"]), "quantity": str(quantity)},
        )
        return {
            "demandId": str(demand_id),
            "status": "OPEN",
            "quantity": str(quantity),
            "unit": commodity["default_unit"],
        }

    async def _create_order(
        self,
        session: AsyncSession,
        *,
        parameters: dict[str, Any],
        actor_user_id: UUID,
        organization: OwnedOrganization,
        idempotency_key: str,
        request_id: str,
        **_: Any,
    ) -> dict[str, Any]:
        return await self._orders.create_order(
            session,
            actor_user_id=actor_user_id,
            buyer=organization,
            command=OrderCreateCommand(
                listing_id=parameters["listingId"],
                demand_id=parameters.get("demandId"),
                quantity=parameters["quantity"],
                delivery_method=parameters["deliveryMethod"],
                delivery_date=parameters["deliveryDate"],
                idempotency_key=idempotency_key,
            ),
            request_id=request_id,
            source="WHATSAPP",
        )

    async def _control_order(
        self,
        session: AsyncSession,
        *,
        intent: str,
        parameters: dict[str, Any],
        actor_user_id: UUID,
        organization: OwnedOrganization,
        request_id: str,
        **_: Any,
    ) -> dict[str, Any]:
        return await self._orders.control_order(
            session,
            actor_user_id=actor_user_id,
            organization=organization,
            order_id=UUID(parameters["targetId"]),
            action=intent,
            reason=parameters.get("reason"),
            request_id=request_id,
            source="WHATSAPP",
        )

    async def _control_listing(
        self,
        session: AsyncSession,
        *,
        intent: str,
        parameters: dict[str, Any],
        actor_user_id: UUID,
        organization: OwnedOrganization,
        request_id: str,
        **_: Any,
    ) -> dict[str, Any]:
        row = (
            await session.execute(
                text(
                    """
                    select l.id, l.status, l.quantity_remaining, b.organization_id,
                           b.quantity_available
                    from public.listings l
                    join public.inventory_batches b on b.id = l.inventory_batch_id
                    where l.id = :id
                    for update of l, b
                    """
                ),
                {"id": UUID(parameters["targetId"])},
            )
        ).mappings().first()
        if row is None:
            raise NotFoundError("Listing tidak ditemukan.")
        if row["organization_id"] != organization.id or organization.type != "FARM":
            raise AuthorizationError()
        if intent == "PAUSE_LISTING":
            if row["status"] != "PUBLISHED":
                raise ConflictError("INVALID_LISTING_STATUS", "Hanya listing terbit dapat dijeda.")
            target = "PAUSED"
        else:
            if row["status"] not in {"DRAFT", "PAUSED"}:
                raise ConflictError("INVALID_LISTING_STATUS", "Listing tidak dapat diterbitkan.")
            if row["quantity_remaining"] <= 0 or row["quantity_available"] <= 0:
                raise ConflictError("INSUFFICIENT_STOCK", "Stok listing tidak tersedia.")
            target = "PUBLISHED"
        await session.execute(
            text(
                """
                update public.listings
                set status = :status,
                    published_at = case when :status = 'PUBLISHED' then coalesce(published_at, now()) else published_at end
                where id = :id
                """
            ),
            {"status": target, "id": row["id"]},
        )
        await self._audit(
            session,
            actor_user_id=actor_user_id,
            action=intent,
            entity_type="listing",
            entity_id=row["id"],
            request_id=request_id,
            data={"oldStatus": row["status"], "newStatus": target},
        )
        return {"listingId": str(row["id"]), "status": target}

    async def _adjust_inventory(
        self,
        session: AsyncSession,
        *,
        parameters: dict[str, Any],
        actor_user_id: UUID,
        organization: OwnedOrganization,
        request_id: str,
        **_: Any,
    ) -> dict[str, Any]:
        row = (
            await session.execute(
                text("select * from public.inventory_batches where id = :id for update"),
                {"id": UUID(parameters["targetId"])},
            )
        ).mappings().first()
        if row is None:
            raise NotFoundError("Batch stok tidak ditemukan.")
        if row["organization_id"] != organization.id or organization.type != "FARM":
            raise AuthorizationError()
        before = Decimal(row["quantity_available"])
        after = Decimal(parameters["quantity"])
        delta = after - before
        total = Decimal(row["quantity_total"]) + delta
        if total <= 0:
            raise ConflictError("INVALID_QUANTITY", "Total stok harus lebih dari nol.")
        status = "SOLD_OUT" if after == 0 else "AVAILABLE"
        await session.execute(
            text(
                """
                update public.inventory_batches
                set quantity_total = :total, quantity_available = :after, status = :status
                where id = :id
                """
            ),
            {"total": total, "after": after, "status": status, "id": row["id"]},
        )
        if delta != 0:
            await session.execute(
                text(
                    """
                    insert into public.inventory_movements (
                      inventory_batch_id, movement_type, quantity,
                      quantity_before, quantity_after, actor_user_id, notes
                    ) values (
                      :id, 'ADJUSTMENT', :quantity, :before, :after,
                      :actor_user_id, 'Confirmed WhatsApp inventory adjustment'
                    )
                    """
                ),
                {
                    "id": row["id"],
                    "quantity": abs(delta),
                    "before": before,
                    "after": after,
                    "actor_user_id": actor_user_id,
                },
            )
        await self._audit(
            session,
            actor_user_id=actor_user_id,
            action="ADJUST_INVENTORY",
            entity_type="inventory_batch",
            entity_id=row["id"],
            request_id=request_id,
            data={"quantityBefore": str(before), "quantityAfter": str(after)},
        )
        return {"inventoryBatchId": str(row["id"]), "quantityAvailable": str(after), "status": status}

    async def _audit(
        self,
        session: AsyncSession,
        *,
        actor_user_id: UUID,
        action: str,
        entity_type: str,
        entity_id: UUID,
        request_id: str,
        data: dict[str, Any],
    ) -> None:
        await session.execute(
            text(
                """
                insert into public.audit_logs (
                  actor_user_id, action, entity_type, entity_id,
                  source, new_data_json, request_id
                ) values (
                  :actor_user_id, :action, :entity_type, :entity_id,
                  'WHATSAPP', cast(:data as jsonb), :request_id
                )
                """
            ),
            {
                "actor_user_id": actor_user_id,
                "action": action,
                "entity_type": entity_type,
                "entity_id": entity_id,
                "data": json.dumps(data, separators=(",", ":")),
                "request_id": request_id,
            },
        )
