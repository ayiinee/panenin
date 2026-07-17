from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user
from app.auth.models import AuthenticatedUser
from app.core.database import get_db_session
from app.core.schemas import success_envelope
from app.demands.schemas import DemandCreateRequest
from app.demands.service import DemandService
from app.matching.schemas import MatchItem
from app.matching.service import MatchingService
from app.organizations.repository import OrganizationRepository

router = APIRouter()
service = DemandService()
matching = MatchingService()
organizations = OrganizationRepository()


@router.get("/demands")
async def list_demands(
    request: Request,
    current_user: AuthenticatedUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    items = await service.list_demands(session, current_user.id)
    return success_envelope(
        request,
        [item.model_dump(by_alias=True, mode="json") for item in items],
    )


@router.post("/demands", status_code=201)
async def create_demand(
    payload: DemandCreateRequest,
    request: Request,
    current_user: AuthenticatedUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    item = await service.create_demand(
        session,
        current_user.id,
        payload,
        request_id=request.state.request_id,
    )
    return success_envelope(request, item.model_dump(by_alias=True, mode="json"))


@router.get("/matches")
async def list_matches(
    request: Request,
    current_user: AuthenticatedUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    organization = await organizations.get_owned_organization(session, current_user.id)
    rows = [] if organization is None else await matching.list_for_organization(
        session,
        organization.id,
    )
    items = [MatchItem.model_validate(row) for row in rows]
    return success_envelope(
        request,
        [item.model_dump(by_alias=True, mode="json") for item in items],
    )
