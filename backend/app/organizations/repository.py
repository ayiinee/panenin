from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.organizations.models import OwnedOrganization


class OrganizationRepository:
    async def get_owned_organization(
        self,
        session: AsyncSession,
        user_id: UUID,
        *,
        for_update: bool = False,
    ) -> OwnedOrganization | None:
        lock = " for update" if for_update else ""
        row = (
            await session.execute(
                text(
                    """
                    select id, type, name, owner_user_id, address_text,
                           latitude, longitude
                    from public.organizations
                    where owner_user_id = :user_id and status = 'ACTIVE'
                    order by created_at
                    limit 1
                    """
                    + lock
                ),
                {"user_id": user_id},
            )
        ).mappings().first()
        if row is None:
            return None
        return OwnedOrganization(
            id=row["id"],
            type=row["type"],
            name=row["name"],
            owner_user_id=row["owner_user_id"],
            address_text=row["address_text"],
            latitude=float(row["latitude"]) if row["latitude"] is not None else None,
            longitude=float(row["longitude"]) if row["longitude"] is not None else None,
        )

    async def get_profile(
        self,
        session: AsyncSession,
        user_id: UUID,
    ) -> dict[str, Any] | None:
        row = (
            await session.execute(
                text(
                    """
                    select u.id as user_id, u.name, o.id as organization_id,
                           o.name as organization_name, o.type as organization_type,
                           o.address_text as address, o.latitude, o.longitude
                    from public.users u
                    join public.organizations o on o.owner_user_id = u.id
                    where u.id = :user_id and o.status = 'ACTIVE'
                    order by o.created_at
                    limit 1
                    """
                ),
                {"user_id": user_id},
            )
        ).mappings().first()
        if row is None:
            return None
        commodities = (
            await session.execute(
                text(
                    """
                    select c.name
                    from public.organization_commodities oc
                    join public.commodities c on c.id = oc.commodity_id
                    where oc.organization_id = :organization_id
                    order by c.name
                    """
                ),
                {"organization_id": row["organization_id"]},
            )
        ).scalars().all()
        return {**dict(row), "commodity_names": list(commodities)}

    async def resolve_commodities(
        self,
        session: AsyncSession,
        names: list[str],
    ) -> list[dict[str, Any]]:
        normalized = sorted({name.strip().casefold() for name in names if name.strip()})
        rows = (
            await session.execute(
                text(
                    """
                    select id, name, default_unit
                    from public.commodities
                    where is_active and lower(name) = any(:names)
                    order by name
                    """
                ),
                {"names": normalized},
            )
        ).mappings().all()
        return [dict(row) for row in rows]
