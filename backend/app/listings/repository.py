from datetime import datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


_LISTING_SELECT = """
select l.id, l.inventory_batch_id, b.organization_id as seller_organization_id,
       o.name as seller_name, b.commodity_id, c.name as commodity,
       l.listing_type, l.price_per_unit, l.minimum_order,
       l.quantity_remaining, l.unit, l.status, b.available_at, b.grade,
       l.published_at, l.expires_at, l.updated_at
from public.listings l
join public.inventory_batches b on b.id = l.inventory_batch_id
join public.commodities c on c.id = b.commodity_id
join public.organizations o on o.id = b.organization_id
"""


class ListingRepository:
    async def list_for_organization(
        self,
        session: AsyncSession,
        organization_id: UUID,
    ) -> list[dict[str, Any]]:
        rows = (
            await session.execute(
                text(
                    _LISTING_SELECT
                    + " where b.organization_id = :organization_id order by l.created_at desc"
                ),
                {"organization_id": organization_id},
            )
        ).mappings().all()
        return [dict(row) for row in rows]

    async def list_catalog(
        self,
        session: AsyncSession,
        *,
        limit: int = 50,
    ) -> list[dict[str, Any]]:
        rows = (
            await session.execute(
                text(
                    _LISTING_SELECT
                    + """
                    where l.status = 'PUBLISHED'
                      and l.quantity_remaining > 0
                      and (l.expires_at is null or l.expires_at > now())
                    order by l.published_at desc nulls last, l.created_at desc
                    limit :limit
                    """
                ),
                {"limit": limit},
            )
        ).mappings().all()
        return [dict(row) for row in rows]

    async def search_catalog(
        self,
        session: AsyncSession,
        *,
        commodity: str,
        quantity: Decimal,
        unit: str,
        max_price: Decimal,
        needed_at: datetime,
        grade_tolerance: list[str] | None = None,
        limit: int = 5,
    ) -> list[dict[str, Any]]:
        grades = [grade.upper() for grade in (grade_tolerance or [])]
        rows = (
            await session.execute(
                text(
                    _LISTING_SELECT
                    + """
                    where l.status = 'PUBLISHED'
                      and l.quantity_remaining > 0
                      and lower(c.name) = lower(:commodity)
                      and lower(l.unit) = lower(:unit)
                      and l.price_per_unit <= :max_price
                      and b.available_at <= :needed_at
                      and (l.expires_at is null or l.expires_at > now())
                      and (
                        cardinality(cast(:grades as text[])) = 0
                        or b.grade is null
                        or upper(b.grade) = any(cast(:grades as text[]))
                      )
                    order by
                      (least(l.quantity_remaining, :quantity) / :quantity) desc,
                      l.price_per_unit asc,
                      b.available_at asc
                    limit :limit
                    """
                ),
                {
                    "commodity": commodity,
                    "quantity": quantity,
                    "unit": unit,
                    "max_price": max_price,
                    "needed_at": needed_at,
                    "grades": grades,
                    "limit": limit,
                },
            )
        ).mappings().all()
        return [dict(row) for row in rows]

    async def get_listing(
        self,
        session: AsyncSession,
        listing_id: UUID,
        *,
        for_update: bool = False,
    ) -> dict[str, Any] | None:
        lock = " for update of l, b" if for_update else ""
        row = (
            await session.execute(
                text(_LISTING_SELECT + " where l.id = :listing_id" + lock),
                {"listing_id": listing_id},
            )
        ).mappings().first()
        return dict(row) if row else None
