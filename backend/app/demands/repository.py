from datetime import datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

_DEMAND_SELECT = """
select d.id, d.buyer_organization_id, o.name as buyer_name,
       d.commodity_id, c.name as commodity, d.quantity,
       d.quantity_remaining, d.unit, d.grade_tolerance, d.max_price,
       d.needed_at, d.status, d.source, d.created_at, d.updated_at,
       d.delivery_latitude, d.delivery_longitude
from public.demands d
join public.organizations o on o.id = d.buyer_organization_id
join public.commodities c on c.id = d.commodity_id
"""


class DemandRepository:
    async def list_owned(
        self,
        session: AsyncSession,
        organization_id: UUID,
    ) -> list[dict[str, Any]]:
        rows = (
            await session.execute(
                text(
                    _DEMAND_SELECT
                    + " where d.buyer_organization_id = :id order by d.created_at desc"
                ),
                {"id": organization_id},
            )
        ).mappings().all()
        return [dict(row) for row in rows]

    async def list_for_farm(
        self,
        session: AsyncSession,
        organization_id: UUID,
    ) -> list[dict[str, Any]]:
        rows = (
            await session.execute(
                text(
                    _DEMAND_SELECT
                    + """
                    where d.status in ('OPEN', 'PARTIALLY_MATCHED')
                      and d.needed_at >= now()
                      and exists (
                        select 1
                        from public.listings l
                        join public.inventory_batches b on b.id = l.inventory_batch_id
                        where b.organization_id = :organization_id
                          and b.commodity_id = d.commodity_id
                          and l.unit = d.unit
                          and l.status = 'PUBLISHED'
                          and l.price_per_unit <= d.max_price
                      )
                    order by d.needed_at, d.created_at desc
                    """
                ),
                {"organization_id": organization_id},
            )
        ).mappings().all()
        return [dict(row) for row in rows]

    async def candidate_demands(
        self,
        session: AsyncSession,
        *,
        commodity: str,
        quantity: Decimal,
        unit: str,
        listing_price: Decimal,
        available_at: datetime,
        grade: str | None,
        seller_organization_id: UUID,
        limit: int = 5,
    ) -> list[dict[str, Any]]:
        rows = (
            await session.execute(
                text(
                    _DEMAND_SELECT
                    + """
                    where d.status in ('OPEN', 'PARTIALLY_MATCHED')
                      and d.quantity_remaining > 0
                      and d.buyer_organization_id <> :seller_organization_id
                      and lower(c.name) = lower(:commodity)
                      and lower(d.unit) = lower(:unit)
                      and d.max_price >= :listing_price
                      and d.needed_at >= :available_at
                      and (
                        cardinality(d.grade_tolerance) = 0
                        or :grade is null
                        or upper(:grade) = any(d.grade_tolerance)
                      )
                    order by
                      (least(d.quantity_remaining, :quantity) / :quantity) desc,
                      d.max_price desc,
                      d.needed_at
                    limit :limit
                    """
                ),
                {
                    "seller_organization_id": seller_organization_id,
                    "commodity": commodity,
                    "quantity": quantity,
                    "unit": unit,
                    "listing_price": listing_price,
                    "available_at": available_at,
                    "grade": grade.upper() if grade else None,
                    "limit": limit,
                },
            )
        ).mappings().all()
        return [dict(row) for row in rows]

    async def get_demand(
        self,
        session: AsyncSession,
        demand_id: UUID,
        *,
        for_update: bool = False,
    ) -> dict[str, Any] | None:
        lock = " for update of d" if for_update else ""
        row = (
            await session.execute(
                text(_DEMAND_SELECT + " where d.id = :demand_id" + lock),
                {"demand_id": demand_id},
            )
        ).mappings().first()
        return dict(row) if row else None
