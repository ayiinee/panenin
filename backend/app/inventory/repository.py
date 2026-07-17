from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


class InventoryRepository:
    async def list_for_organization(
        self,
        session: AsyncSession,
        organization_id: UUID,
    ) -> list[dict[str, Any]]:
        rows = (
            await session.execute(
                text(
                    """
                    select b.id, b.organization_id, b.commodity_id,
                           c.name as commodity, b.quantity_total,
                           b.quantity_available,
                           coalesce(sum(r.quantity) filter (
                             where r.status = 'ACTIVE' and r.expires_at > now()
                           ), 0) as quantity_reserved,
                           b.unit, b.grade, b.harvested_at, b.available_at,
                           b.minimum_price, b.status, b.updated_at
                    from public.inventory_batches b
                    join public.commodities c on c.id = b.commodity_id
                    left join public.inventory_reservations r
                      on r.inventory_batch_id = b.id
                    where b.organization_id = :organization_id
                    group by b.id, c.name
                    order by b.created_at desc
                    """
                ),
                {"organization_id": organization_id},
            )
        ).mappings().all()
        return [dict(row) for row in rows]

    async def get_batch(
        self,
        session: AsyncSession,
        batch_id: UUID,
        *,
        for_update: bool = False,
    ) -> dict[str, Any] | None:
        lock = " for update" if for_update else ""
        row = (
            await session.execute(
                text(
                    """
                    select b.*, c.name as commodity, c.default_unit
                    from public.inventory_batches b
                    join public.commodities c on c.id = b.commodity_id
                    where b.id = :batch_id
                    """
                    + lock
                ),
                {"batch_id": batch_id},
            )
        ).mappings().first()
        return dict(row) if row else None
