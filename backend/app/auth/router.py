from fastapi import APIRouter, Depends, Request

from app.auth.dependencies import get_current_user
from app.auth.models import AuthenticatedUser, AuthMeResponse

router = APIRouter()


@router.get("/me", response_model=AuthMeResponse)
async def get_me(
    request: Request,
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> AuthMeResponse:
    return AuthMeResponse(
        data=current_user,
        request_id=request.state.request_id,
    )
