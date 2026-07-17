from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.agent_api.schemas import (
    BuyPreviewRequest,
    CancelActionRequest,
    CatalogSearchRequest,
    ConfirmActionRequest,
    ControlPreviewRequest,
    IdentityLinkRequest,
    IdentityResolveRequest,
    OrderPreviewRequest,
    SellPreviewRequest,
)
from app.agent_api.security import require_agent_service
from app.agent_api.service import AgentService
from app.core.database import get_db_session
from app.core.schemas import success_envelope

router = APIRouter(dependencies=[Depends(require_agent_service)])
service = AgentService()


@router.post("/identity/resolve")
async def resolve_identity(
    payload: IdentityResolveRequest,
    request: Request,
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    result = await service.resolve_identity(session, payload.channel_subject)
    return success_envelope(request, result)


@router.post("/identity/link")
async def link_identity(
    payload: IdentityLinkRequest,
    request: Request,
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    result = await service.link_identity(
        session,
        subject=payload.channel_subject,
        link_code=payload.link_code,
        request_id=request.state.request_id,
    )
    return success_envelope(request, result)


@router.get("/context")
async def context(
    request: Request,
    channel_subject: Annotated[str, Query(alias="channelSubject", pattern=r"^wa:v1:[0-9a-f]{16,128}$")],
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    return success_envelope(request, await service.context(session, channel_subject))


@router.get("/inventory")
async def inventory(
    request: Request,
    channel_subject: Annotated[str, Query(alias="channelSubject", pattern=r"^wa:v1:[0-9a-f]{16,128}$")],
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    return success_envelope(request, await service.inventory(session, channel_subject))


@router.get("/demands")
async def demands(
    request: Request,
    channel_subject: Annotated[str, Query(alias="channelSubject", pattern=r"^wa:v1:[0-9a-f]{16,128}$")],
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    return success_envelope(request, await service.demands(session, channel_subject))


@router.get("/orders")
async def orders(
    request: Request,
    channel_subject: Annotated[str, Query(alias="channelSubject", pattern=r"^wa:v1:[0-9a-f]{16,128}$")],
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    return success_envelope(request, await service.orders(session, channel_subject))


@router.get("/control/overview")
async def control_overview(
    request: Request,
    channel_subject: Annotated[str, Query(alias="channelSubject", pattern=r"^wa:v1:[0-9a-f]{16,128}$")],
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    return success_envelope(request, await service.context(session, channel_subject))


@router.post("/catalog/search")
async def catalog_search(
    payload: CatalogSearchRequest,
    request: Request,
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    return success_envelope(request, await service.catalog_search(session, payload))


@router.post("/sell/preview")
async def sell_preview(
    payload: SellPreviewRequest,
    request: Request,
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    result = await service.sell_preview(session, payload)
    return success_envelope(request, result.model_dump(by_alias=True, mode="json", exclude_none=True))


@router.post("/buy/preview")
async def buy_preview(
    payload: BuyPreviewRequest,
    request: Request,
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    result = await service.buy_preview(session, payload)
    return success_envelope(request, result.model_dump(by_alias=True, mode="json", exclude_none=True))


@router.post("/orders/preview")
async def order_preview(
    payload: OrderPreviewRequest,
    request: Request,
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    result = await service.order_preview(session, payload)
    return success_envelope(request, result.model_dump(by_alias=True, mode="json", exclude_none=True))


@router.post("/control/preview")
async def control_preview(
    payload: ControlPreviewRequest,
    request: Request,
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    result = await service.control_preview(session, payload)
    return success_envelope(request, result.model_dump(by_alias=True, mode="json", exclude_none=True))


@router.post("/actions/{action_id}/confirm")
async def confirm_action(
    action_id: UUID,
    payload: ConfirmActionRequest,
    request: Request,
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    result = await service.confirm_action(
        session,
        action_id,
        payload,
        request_id=request.state.request_id,
    )
    return success_envelope(request, result)


@router.post("/actions/{action_id}/cancel")
async def cancel_action(
    action_id: UUID,
    payload: CancelActionRequest,
    request: Request,
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    result = await service.cancel_action(
        session,
        action_id,
        payload.channel_subject,
        request_id=request.state.request_id,
    )
    return success_envelope(request, result)
