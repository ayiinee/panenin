from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user
from app.auth.models import AuthenticatedUser
from app.core.database import get_db_session
from app.core.schemas import success_envelope
from app.listings.service import ListingService

router = APIRouter()
service = ListingService()


@router.get("/listings")
async def list_owned(
    request: Request,
    current_user: AuthenticatedUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    items = await service.list_owned(session, current_user.id)
    return success_envelope(
        request,
        [item.model_dump(by_alias=True, mode="json") for item in items],
    )


@router.get("/catalog/listings")
async def list_catalog(
    request: Request,
    current_user: AuthenticatedUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    del current_user
    items = await service.catalog(session)
    return success_envelope(
        request,
        [item.model_dump(by_alias=True, mode="json") for item in items],
    )
