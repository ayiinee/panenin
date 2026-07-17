from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user
from app.auth.models import AuthenticatedUser
from app.core.database import get_db_session
from app.core.schemas import success_envelope
from app.organizations.schemas import ProfileUpsertRequest
from app.organizations.service import OrganizationService

router = APIRouter()
service = OrganizationService()


@router.get("/me/profile")
async def get_profile(
    request: Request,
    current_user: AuthenticatedUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    profile = await service.get_profile(session, current_user.id)
    return success_envelope(request, profile.model_dump(by_alias=True, mode="json"))


@router.put("/me/profile")
async def upsert_profile(
    payload: ProfileUpsertRequest,
    request: Request,
    current_user: AuthenticatedUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    profile = await service.upsert_profile(
        session,
        current_user.id,
        payload,
        request_id=request.state.request_id,
    )
    return success_envelope(request, profile.model_dump(by_alias=True, mode="json"))
