from uuid import UUID

from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user
from app.auth.models import AuthenticatedUser
from app.core.database import get_db_session
from app.core.schemas import success_envelope
from app.orders.service import OrderService

router = APIRouter()
service = OrderService()


@router.get("/orders")
async def list_orders(
    request: Request,
    current_user: AuthenticatedUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    items = await service.list_orders(session, current_user.id)
    return success_envelope(
        request,
        [item.model_dump(by_alias=True, mode="json") for item in items],
    )


@router.get("/orders/{order_id}")
async def get_order(
    order_id: UUID,
    request: Request,
    current_user: AuthenticatedUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    item = await service.get_order_for_user(session, current_user.id, order_id)
    return success_envelope(request, item.model_dump(by_alias=True, mode="json"))
