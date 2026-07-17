from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user
from app.auth.models import AuthenticatedUser
from app.core.database import get_db_session
from app.core.schemas import success_envelope
from app.whatsapp.linking import WhatsAppLinkingService

router = APIRouter()
service = WhatsAppLinkingService()


@router.post("/whatsapp/link-code", status_code=201)
async def create_link_code(
    request: Request,
    current_user: AuthenticatedUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    result = await service.create_link_code(
        session,
        current_user.id,
        request_id=request.state.request_id,
    )
    return success_envelope(request, result.model_dump(by_alias=True, mode="json"))


@router.get("/whatsapp/status")
async def whatsapp_status(
    request: Request,
    current_user: AuthenticatedUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict:
    result = await service.status(session, current_user.id)
    return success_envelope(request, result.model_dump(by_alias=True, mode="json"))
