from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ConflictError, NotFoundError
from app.core.schemas import success_envelope
from app.organizations.repository import OrganizationRepository
from app.organizations.schemas import ProfileResponse, ProfileUpsertRequest


class OrganizationService:
    def __init__(self, repository: OrganizationRepository | None = None) -> None:
        self._repository = repository or OrganizationRepository()

    async def get_profile(
        self,
        session: AsyncSession,
        user_id: UUID,
    ) -> ProfileResponse:
        profile = await self._repository.get_profile(session, user_id)
        if profile is None:
            raise NotFoundError("Profil belum dilengkapi.")
        return ProfileResponse.model_validate(profile)

    async def upsert_profile(
        self,
        session: AsyncSession,
        user_id: UUID,
        payload: ProfileUpsertRequest,
        *,
        request_id: str,
    ) -> ProfileResponse:
        requested_names = {name.strip().casefold() for name in payload.commodity_names}
        async with session.begin():
            commodities = await self._repository.resolve_commodities(
                session,
                payload.commodity_names,
            )
            found_names = {item["name"].casefold() for item in commodities}
            missing = sorted(requested_names - found_names)
            if missing:
                raise ConflictError(
                    "UNKNOWN_COMMODITY",
                    "Satu atau lebih komoditas belum tersedia.",
                )

            await session.execute(
                text("update public.users set name = :name where id = :user_id"),
                {"name": payload.name, "user_id": user_id},
            )
            organization = await self._repository.get_owned_organization(
                session,
                user_id,
                for_update=True,
            )
            if organization is None:
                organization_id = (
                    await session.execute(
                        text(
                            """
                            insert into public.organizations (
                              type, name, owner_user_id, address_text, latitude, longitude
                            ) values (
                              :type, :name, :user_id, :address, :latitude, :longitude
                            ) returning id
                            """
                        ),
                        {
                            "type": payload.organization_type,
                            "name": payload.organization_name,
                            "user_id": user_id,
                            "address": payload.address,
                            "latitude": payload.latitude,
                            "longitude": payload.longitude,
                        },
                    )
                ).scalar_one()
            else:
                organization_id = organization.id
                await session.execute(
                    text(
                        """
                        update public.organizations
                        set type = :type, name = :name, address_text = :address,
                            latitude = :latitude, longitude = :longitude
                        where id = :organization_id
                        """
                    ),
                    {
                        "type": payload.organization_type,
                        "name": payload.organization_name,
                        "address": payload.address,
                        "latitude": payload.latitude,
                        "longitude": payload.longitude,
                        "organization_id": organization_id,
                    },
                )

            await session.execute(
                text(
                    "delete from public.organization_commodities where organization_id = :id"
                ),
                {"id": organization_id},
            )
            for commodity in commodities:
                await session.execute(
                    text(
                        """
                        insert into public.organization_commodities
                          (organization_id, commodity_id)
                        values (:organization_id, :commodity_id)
                        """
                    ),
                    {
                        "organization_id": organization_id,
                        "commodity_id": commodity["id"],
                    },
                )
            await session.execute(
                text(
                    """
                    insert into public.audit_logs (
                      actor_user_id, action, entity_type, entity_id, source,
                      new_data_json, request_id
                    ) values (
                      :user_id, 'UPSERT_PROFILE', 'organization', :organization_id,
                      'APP', cast(:new_data as jsonb), :request_id
                    )
                    """
                ),
                {
                    "user_id": user_id,
                    "organization_id": organization_id,
                    "new_data": (
                        '{"organizationType":"'
                        + payload.organization_type
                        + '","commodityCount":'
                        + str(len(commodities))
                        + "}"
                    ),
                    "request_id": request_id,
                },
            )

        return await self.get_profile(session, user_id)
