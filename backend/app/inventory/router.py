from uuid import UUID

from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user
from app.auth.models import AuthenticatedUser
from app.core.database import get_db_session
from app.core.schemas import success_envelope
from app.inventory.schemas import InventoryCreateRequest, InventoryPatchRequest
from app.inventory.service import InventoryService

router = APIRouter()
service = InventoryService()


@router.get("/inventory")
async def list_inventory(
    request: Request,
    current_user: AuthenticatedUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    items = await service.list_inventory(session, current_user.id)
    return success_envelope(
        request,
        [item.model_dump(by_alias=True, mode="json") for item in items],
    )


@router.post("/inventory", status_code=201)
async def create_inventory(
    payload: InventoryCreateRequest,
    request: Request,
    current_user: AuthenticatedUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    item = await service.create_inventory(
        session,
        current_user.id,
        payload,
        request_id=request.state.request_id,
    )
    return success_envelope(request, item.model_dump(by_alias=True, mode="json"))


@router.patch("/inventory/{batch_id}")
async def patch_inventory(
    batch_id: UUID,
    payload: InventoryPatchRequest,
    request: Request,
    current_user: AuthenticatedUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    item = await service.patch_inventory(
        session,
        current_user.id,
        batch_id,
        payload,
        request_id=request.state.request_id,
    )
    return success_envelope(request, item.model_dump(by_alias=True, mode="json"))
