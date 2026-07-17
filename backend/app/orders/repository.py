from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

_ORDER_SELECT = """
select ord.id, ord.order_number, ord.buyer_organization_id,
       buyer.name as buyer_name, ord.seller_organization_id,
       seller.name as seller_name, ord.demand_id, ord.listing_id,
       c.name as commodity, ord.quantity, ord.unit, ord.unit_price,
       ord.subtotal, ord.delivery_fee, ord.total_amount,
       ord.delivery_method, ord.delivery_date,
       ord.delivery_address_text as delivery_address,
       ord.status, ord.created_at, ord.updated_at,
       l.inventory_batch_id
from public.orders ord
join public.organizations buyer on buyer.id = ord.buyer_organization_id
join public.organizations seller on seller.id = ord.seller_organization_id
join public.listings l on l.id = ord.listing_id
join public.inventory_batches b on b.id = l.inventory_batch_id
join public.commodities c on c.id = b.commodity_id
"""


class OrderRepository:
    async def list_for_organization(
        self,
        session: AsyncSession,
        organization_id: UUID,
    ) -> list[dict[str, Any]]:
        rows = (
            await session.execute(
                text(
                    _ORDER_SELECT
                    + """
                    where ord.buyer_organization_id = :organization_id
                       or ord.seller_organization_id = :organization_id
                    order by ord.created_at desc
                    """
                ),
                {"organization_id": organization_id},
            )
        ).mappings().all()
        return [dict(row) for row in rows]

    async def get_order(
        self,
        session: AsyncSession,
        order_id: UUID,
        *,
        for_update: bool = False,
    ) -> dict[str, Any] | None:
        lock = " for update of ord" if for_update else ""
        row = (
            await session.execute(
                text(_ORDER_SELECT + " where ord.id = :order_id" + lock),
                {"order_id": order_id},
            )
        ).mappings().first()
        return dict(row) if row else None

    async def get_reservation(
        self,
        session: AsyncSession,
        order_id: UUID,
        *,
        for_update: bool = False,
    ) -> dict[str, Any] | None:
        lock = " for update" if for_update else ""
        row = (
            await session.execute(
                text(
                    """
                    select * from public.inventory_reservations
                    where order_id = :order_id
                    order by created_at desc
                    limit 1
                    """
                    + lock
                ),
                {"order_id": order_id},
            )
        ).mappings().first()
        return dict(row) if row else None
