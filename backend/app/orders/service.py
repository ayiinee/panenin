import json
from datetime import UTC, datetime, timedelta
from decimal import Decimal, ROUND_HALF_UP
from uuid import UUID, uuid4

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.database import set_transaction_actor
from app.core.errors import AuthorizationError, ConflictError, NotFoundError
from app.demands.repository import DemandRepository
from app.listings.repository import ListingRepository
from app.orders.repository import OrderRepository
from app.orders.schemas import OrderCreateCommand, OrderItem
from app.organizations.models import OwnedOrganization
from app.organizations.repository import OrganizationRepository


class OrderService:
    def __init__(self) -> None:
        self._repository = OrderRepository()
        self._organizations = OrganizationRepository()
        self._listings = ListingRepository()
        self._demands = DemandRepository()

    async def list_orders(
        self,
        session: AsyncSession,
        user_id: UUID,
    ) -> list[OrderItem]:
        organization = await self._organizations.get_owned_organization(session, user_id)
        if organization is None:
            return []
        rows = await self._repository.list_for_organization(session, organization.id)
        return [OrderItem.model_validate(row) for row in rows]

    async def get_order_for_user(
        self,
        session: AsyncSession,
        user_id: UUID,
        order_id: UUID,
    ) -> OrderItem:
        organization = await self._organizations.get_owned_organization(session, user_id)
        row = await self._repository.get_order(session, order_id)
        if organization is None or row is None:
            raise NotFoundError("Pesanan tidak ditemukan.")
        if organization.id not in {
            row["buyer_organization_id"],
            row["seller_organization_id"],
        }:
            raise AuthorizationError()
        return OrderItem.model_validate(row)

    async def create_order(
        self,
        session: AsyncSession,
        *,
        actor_user_id: UUID,
        buyer: OwnedOrganization,
        command: OrderCreateCommand,
        request_id: str,
        source: str,
    ) -> dict:
        if buyer.type != "UMKM":
            raise AuthorizationError("Hanya organisasi UMKM dapat membuat pesanan.")
        await set_transaction_actor(
            session,
            source=source,
            actor_user_id=str(actor_user_id),
        )
        listing = await self._listings.get_listing(
            session,
            command.listing_id,
            for_update=True,
        )
        if listing is None:
            raise NotFoundError("Listing tidak ditemukan.")
        if listing["status"] != "PUBLISHED":
            raise ConflictError("LISTING_UNAVAILABLE", "Listing tidak lagi tersedia.")
        if listing["seller_organization_id"] == buyer.id:
            raise ConflictError("SELF_ORDER", "Organisasi tidak dapat membeli listing sendiri.")
        if command.quantity < Decimal(listing["minimum_order"]):
            raise ConflictError("MINIMUM_ORDER", "Jumlah di bawah minimum order.")
        if command.quantity > Decimal(listing["quantity_remaining"]):
            raise ConflictError("INSUFFICIENT_STOCK", "Stok listing tidak mencukupi.")

        demand = None
        if command.demand_id is not None:
            demand = await self._demands.get_demand(
                session,
                command.demand_id,
                for_update=True,
            )
            if demand is None:
                raise NotFoundError("Permintaan tidak ditemukan.")
            if demand["buyer_organization_id"] != buyer.id:
                raise AuthorizationError("Permintaan tidak dimiliki organisasi ini.")
            if demand["commodity_id"] != listing["commodity_id"] or demand["unit"] != listing["unit"]:
                raise ConflictError("DEMAND_MISMATCH", "Permintaan tidak sesuai listing.")
            if command.quantity > Decimal(demand["quantity_remaining"]):
                raise ConflictError("DEMAND_QUANTITY", "Jumlah melebihi sisa permintaan.")

        batch = (
            await session.execute(
                text(
                    "select * from public.inventory_batches where id = :id for update"
                ),
                {"id": listing["inventory_batch_id"]},
            )
        ).mappings().one()
        if command.quantity > Decimal(batch["quantity_available"]):
            raise ConflictError("INSUFFICIENT_STOCK", "Stok batch tidak mencukupi.")

        unit_price = Decimal(listing["price_per_unit"])
        subtotal = (command.quantity * unit_price).quantize(
            Decimal("0.01"),
            rounding=ROUND_HALF_UP,
        )
        delivery_fee = Decimal("0.00")
        total = subtotal + delivery_fee
        order_id = uuid4()
        order_number = f"PNN-{datetime.now(UTC):%Y%m%d}-{order_id.hex[:8].upper()}"
        row = (
            await session.execute(
                text(
                    """
                    insert into public.orders (
                      id, order_number, idempotency_key, buyer_organization_id,
                      seller_organization_id, demand_id, listing_id, quantity,
                      unit, unit_price, subtotal, delivery_fee, total_amount,
                      delivery_method, delivery_date, delivery_address_text,
                      delivery_latitude, delivery_longitude, status
                    ) values (
                      :id, :order_number, :idempotency_key, :buyer_id,
                      :seller_id, :demand_id, :listing_id, :quantity,
                      :unit, :unit_price, :subtotal, :delivery_fee, :total,
                      :delivery_method, :delivery_date, :address,
                      :latitude, :longitude, 'PENDING_SELLER'
                    ) returning *
                    """
                ),
                {
                    "id": order_id,
                    "order_number": order_number,
                    "idempotency_key": command.idempotency_key,
                    "buyer_id": buyer.id,
                    "seller_id": listing["seller_organization_id"],
                    "demand_id": command.demand_id,
                    "listing_id": command.listing_id,
                    "quantity": command.quantity,
                    "unit": listing["unit"],
                    "unit_price": unit_price,
                    "subtotal": subtotal,
                    "delivery_fee": delivery_fee,
                    "total": total,
                    "delivery_method": command.delivery_method,
                    "delivery_date": command.delivery_date,
                    "address": buyer.address_text,
                    "latitude": buyer.latitude,
                    "longitude": buyer.longitude,
                },
            )
        ).mappings().one()

        reservation_expiry = datetime.now(UTC) + timedelta(
            seconds=get_settings().order_reservation_ttl_seconds
        )
        await session.execute(
            text(
                """
                insert into public.inventory_reservations (
                  inventory_batch_id, order_id, quantity, status, expires_at
                ) values (
                  :batch_id, :order_id, :quantity, 'ACTIVE', :expires_at
                )
                """
            ),
            {
                "batch_id": listing["inventory_batch_id"],
                "order_id": order_id,
                "quantity": command.quantity,
                "expires_at": reservation_expiry,
            },
        )
        batch_after = Decimal(batch["quantity_available"]) - command.quantity
        batch_status = "SOLD_OUT" if batch_after == 0 else "PARTIALLY_RESERVED"
        await session.execute(
            text(
                """
                update public.inventory_batches
                set quantity_available = :after, status = :status
                where id = :batch_id
                """
            ),
            {"after": batch_after, "status": batch_status, "batch_id": listing["inventory_batch_id"]},
        )
        listing_after = Decimal(listing["quantity_remaining"]) - command.quantity
        await session.execute(
            text(
                """
                update public.listings
                set quantity_remaining = :after,
                    status = case when :after = 0 then 'SOLD_OUT' else status end
                where id = :listing_id
                """
            ),
            {"after": listing_after, "listing_id": command.listing_id},
        )
        if demand is not None:
            demand_after = Decimal(demand["quantity_remaining"]) - command.quantity
            await session.execute(
                text(
                    """
                    update public.demands
                    set quantity_remaining = :after,
                        status = case when :after = 0 then 'MATCHED' else 'PARTIALLY_MATCHED' end
                    where id = :demand_id
                    """
                ),
                {"after": demand_after, "demand_id": command.demand_id},
            )
        await session.execute(
            text(
                """
                insert into public.inventory_movements (
                  inventory_batch_id, movement_type, quantity,
                  quantity_before, quantity_after, reference_type,
                  reference_id, actor_user_id, notes
                ) values (
                  :batch_id, 'RESERVE', :quantity, :before, :after,
                  'ORDER', :order_id, :actor_user_id,
                  'Reserved by confirmed Panenin Core action'
                )
                """
            ),
            {
                "batch_id": listing["inventory_batch_id"],
                "quantity": command.quantity,
                "before": batch["quantity_available"],
                "after": batch_after,
                "order_id": order_id,
                "actor_user_id": actor_user_id,
            },
        )
        await self._audit(
            session,
            actor_user_id=actor_user_id,
            action="CREATE_ORDER",
            entity_id=order_id,
            source=source,
            request_id=request_id,
            data={"orderNumber": order_number, "quantity": str(command.quantity)},
        )
        return {
            "id": str(order_id),
            "orderNumber": order_number,
            "status": row["status"],
            "quantity": str(command.quantity),
            "unit": listing["unit"],
            "unitPrice": str(unit_price),
            "subtotal": str(subtotal),
            "deliveryFee": str(delivery_fee),
            "totalAmount": str(total),
            "reservationExpiresAt": reservation_expiry.isoformat(),
        }

    async def control_order(
        self,
        session: AsyncSession,
        *,
        actor_user_id: UUID,
        organization: OwnedOrganization,
        order_id: UUID,
        action: str,
        reason: str | None,
        request_id: str,
        source: str,
    ) -> dict:
        await set_transaction_actor(
            session,
            source=source,
            actor_user_id=str(actor_user_id),
        )
        order = await self._repository.get_order(session, order_id, for_update=True)
        if order is None:
            raise NotFoundError("Pesanan tidak ditemukan.")
        is_buyer = organization.id == order["buyer_organization_id"]
        is_seller = organization.id == order["seller_organization_id"]
        if not is_buyer and not is_seller:
            raise AuthorizationError()

        target_status = {
            "ACCEPT_ORDER": "ACCEPTED",
            "REJECT_ORDER": "REJECTED",
            "MARK_ORDER_READY": "READY",
            "CANCEL_ORDER": "CANCELLED",
            "COMPLETE_ORDER": "COMPLETED",
        }.get(action)
        if target_status is None:
            raise ConflictError("UNKNOWN_ACTION", "Aksi order tidak dikenali.")
        if action in {"ACCEPT_ORDER", "REJECT_ORDER", "MARK_ORDER_READY"} and not is_seller:
            raise AuthorizationError("Aksi ini hanya tersedia untuk penjual.")
        if action == "COMPLETE_ORDER" and not is_buyer:
            raise AuthorizationError("Penyelesaian pesanan harus dikonfirmasi pembeli.")

        reservation = await self._repository.get_reservation(
            session,
            order_id,
            for_update=True,
        )
        if target_status in {"REJECTED", "CANCELLED"} and reservation and reservation["status"] == "ACTIVE":
            await self._release_reservation(
                session,
                order=order,
                reservation=reservation,
                actor_user_id=actor_user_id,
            )
        elif target_status == "COMPLETED":
            if reservation is None or reservation["status"] != "ACTIVE":
                raise ConflictError("RESERVATION_INACTIVE", "Reservasi pesanan tidak aktif.")
            await session.execute(
                text(
                    "update public.inventory_reservations set status = 'CONSUMED' where id = :id"
                ),
                {"id": reservation["id"]},
            )
            batch_available = (
                await session.execute(
                    text(
                        "select quantity_available from public.inventory_batches where id = :id for update"
                    ),
                    {"id": reservation["inventory_batch_id"]},
                )
            ).scalar_one()
            await session.execute(
                text(
                    """
                    insert into public.inventory_movements (
                      inventory_batch_id, movement_type, quantity,
                      quantity_before, quantity_after, reference_type,
                      reference_id, actor_user_id, notes
                    ) values (
                      :batch_id, 'SOLD', :quantity, :available, :available,
                      'ORDER', :order_id, :actor_user_id,
                      'Reservation consumed on completed order'
                    )
                    """
                ),
                {
                    "batch_id": reservation["inventory_batch_id"],
                    "quantity": reservation["quantity"],
                    "available": batch_available,
                    "order_id": order_id,
                    "actor_user_id": actor_user_id,
                },
            )

        await session.execute(
            text(
                """
                update public.orders
                set status = :status,
                    rejection_reason = case when :status = 'REJECTED' then :reason else rejection_reason end,
                    cancellation_reason = case when :status = 'CANCELLED' then :reason else cancellation_reason end
                where id = :order_id
                """
            ),
            {"status": target_status, "reason": reason, "order_id": order_id},
        )
        await self._audit(
            session,
            actor_user_id=actor_user_id,
            action=action,
            entity_id=order_id,
            source=source,
            request_id=request_id,
            data={"oldStatus": order["status"], "newStatus": target_status},
        )
        return {"id": str(order_id), "status": target_status}

    async def _release_reservation(
        self,
        session: AsyncSession,
        *,
        order: dict,
        reservation: dict,
        actor_user_id: UUID,
    ) -> None:
        batch = (
            await session.execute(
                text("select * from public.inventory_batches where id = :id for update"),
                {"id": reservation["inventory_batch_id"]},
            )
        ).mappings().one()
        listing = await self._listings.get_listing(
            session,
            order["listing_id"],
            for_update=True,
        )
        quantity = Decimal(reservation["quantity"])
        batch_after = Decimal(batch["quantity_available"]) + quantity
        await session.execute(
            text(
                """
                update public.inventory_batches
                set quantity_available = :after,
                    status = case when :after > 0 then 'AVAILABLE' else status end
                where id = :id
                """
            ),
            {"after": batch_after, "id": batch["id"]},
        )
        if listing is not None:
            listing_after = min(
                Decimal(listing["quantity_remaining"]) + quantity,
                Decimal(listing["quantity_remaining"]) + quantity,
            )
            await session.execute(
                text(
                    """
                    update public.listings
                    set quantity_remaining = least(quantity_listed, :after),
                        status = case when status = 'SOLD_OUT' then 'PUBLISHED' else status end
                    where id = :id
                    """
                ),
                {"after": listing_after, "id": listing["id"]},
            )
        if order["demand_id"] is not None:
            await session.execute(
                text(
                    """
                    update public.demands
                    set quantity_remaining = least(quantity, quantity_remaining + :released),
                        status = case
                          when quantity_remaining + :released >= quantity then 'OPEN'
                          else 'PARTIALLY_MATCHED'
                        end
                    where id = :id
                    """
                ),
                {"released": quantity, "id": order["demand_id"]},
            )
        await session.execute(
            text(
                "update public.inventory_reservations set status = 'RELEASED' where id = :id"
            ),
            {"id": reservation["id"]},
        )
        await session.execute(
            text(
                """
                insert into public.inventory_movements (
                  inventory_batch_id, movement_type, quantity,
                  quantity_before, quantity_after, reference_type,
                  reference_id, actor_user_id, notes
                ) values (
                  :batch_id, 'RELEASE', :quantity, :before, :after,
                  'ORDER', :order_id, :actor_user_id,
                  'Reservation released by order transition'
                )
                """
            ),
            {
                "batch_id": batch["id"],
                "quantity": quantity,
                "before": batch["quantity_available"],
                "after": batch_after,
                "order_id": order["id"],
                "actor_user_id": actor_user_id,
            },
        )

    async def _audit(
        self,
        session: AsyncSession,
        *,
        actor_user_id: UUID,
        action: str,
        entity_id: UUID,
        source: str,
        request_id: str,
        data: dict,
    ) -> None:
        await session.execute(
            text(
                """
                insert into public.audit_logs (
                  actor_user_id, action, entity_type, entity_id,
                  source, new_data_json, request_id
                ) values (
                  :actor_user_id, :action, 'order', :entity_id,
                  :source, cast(:data as jsonb), :request_id
                )
                """
            ),
            {
                "actor_user_id": actor_user_id,
                "action": action,
                "entity_id": entity_id,
                "source": source,
                "data": json.dumps(data, separators=(",", ":")),
                "request_id": request_id,
            },
        )
