import json
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import AuthorizationError, ConflictError, NotFoundError
from app.demands.repository import DemandRepository
from app.demands.schemas import DemandCreateRequest, DemandItem
from app.matching.service import MatchingService
from app.organizations.repository import OrganizationRepository


class DemandService:
    def __init__(self) -> None:
        self._repository = DemandRepository()
        self._organizations = OrganizationRepository()
        self._matching = MatchingService(demands=self._repository)

    async def list_demands(
        self,
        session: AsyncSession,
        user_id: UUID,
    ) -> list[DemandItem]:
        organization = await self._organizations.get_owned_organization(session, user_id)
        if organization is None:
            return []
        if organization.type == "UMKM":
            rows = await self._repository.list_owned(session, organization.id)
        else:
            rows = await self._repository.list_for_farm(session, organization.id)
        return [DemandItem.model_validate(row) for row in rows]

    async def create_demand(
        self,
        session: AsyncSession,
        user_id: UUID,
        payload: DemandCreateRequest,
        *,
        request_id: str,
        source: str = "APP",
    ) -> DemandItem:
        async with session.begin():
            organization = await self._organizations.get_owned_organization(
                session,
                user_id,
                for_update=True,
            )
            if organization is None:
                raise NotFoundError("Profil organisasi belum dilengkapi.")
            if organization.type != "UMKM":
                raise AuthorizationError("Hanya organisasi UMKM dapat membuat permintaan.")
            commodity = (
                await session.execute(
                    text(
                        """
                        select id, name, default_unit from public.commodities
                        where is_active and lower(name) = lower(:name)
                        """
                    ),
                    {"name": payload.commodity},
                )
            ).mappings().first()
            if commodity is None:
                raise NotFoundError("Komoditas tidak ditemukan.")
            if commodity["default_unit"].casefold() != payload.unit.casefold():
                raise ConflictError("UNIT_MISMATCH", "Satuan komoditas tidak sesuai.")
            row = (
                await session.execute(
                    text(
                        """
                        insert into public.demands (
                          buyer_organization_id, commodity_id, quantity,
                          quantity_remaining, unit, grade_tolerance, max_price,
                          needed_at, delivery_address_text, delivery_latitude,
                          delivery_longitude, status, source
                        ) values (
                          :organization_id, :commodity_id, :quantity,
                          :quantity, :unit, :grades, :max_price,
                          :needed_at, :address, :latitude, :longitude,
                          'OPEN', :source
                        ) returning *
                        """
                    ),
                    {
                        "organization_id": organization.id,
                        "commodity_id": commodity["id"],
                        "quantity": payload.quantity,
                        "unit": commodity["default_unit"],
                        "grades": [grade.upper() for grade in payload.grade_tolerance],
                        "max_price": payload.max_price,
                        "needed_at": payload.needed_at,
                        "address": payload.delivery_address or organization.address_text,
                        "latitude": payload.delivery_latitude,
                        "longitude": payload.delivery_longitude,
                        "source": source,
                    },
                )
            ).mappings().one()
            demand = {
                **dict(row),
                "buyer_name": organization.name,
                "commodity": commodity["name"],
            }
            await self._matching.persist_for_demand(session, demand)
            await session.execute(
                text(
                    """
                    insert into public.audit_logs (
                      actor_user_id, action, entity_type, entity_id, source,
                      new_data_json, request_id
                    ) values (
                      :user_id, 'CREATE_DEMAND', 'demand', :entity_id, :source,
                      cast(:data as jsonb), :request_id
                    )
                    """
                ),
                {
                    "user_id": user_id,
                    "entity_id": row["id"],
                    "source": source,
                    "data": json.dumps(
                        {"commodityId": str(commodity["id"]), "quantity": str(payload.quantity)},
                        separators=(",", ":"),
                    ),
                    "request_id": request_id,
                },
            )
        return DemandItem.model_validate(demand)
