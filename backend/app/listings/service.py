from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.listings.repository import ListingRepository
from app.listings.schemas import ListingItem
from app.organizations.repository import OrganizationRepository


class ListingService:
    def __init__(
        self,
        repository: ListingRepository | None = None,
        organizations: OrganizationRepository | None = None,
    ) -> None:
        self._repository = repository or ListingRepository()
        self._organizations = organizations or OrganizationRepository()

    async def list_owned(
        self,
        session: AsyncSession,
        user_id: UUID,
    ) -> list[ListingItem]:
        organization = await self._organizations.get_owned_organization(session, user_id)
        if organization is None:
            return []
        rows = await self._repository.list_for_organization(session, organization.id)
        return [ListingItem.model_validate(row) for row in rows]

    async def catalog(self, session: AsyncSession) -> list[ListingItem]:
        rows = await self._repository.list_catalog(session)
        return [ListingItem.model_validate(row) for row in rows]
