from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class AuthenticatedUser(BaseModel):
    id: UUID
    email: EmailStr | None = None
    name: str | None = None
    provider: str | None = None
    role: Literal["FARMER", "BUYER"] | None = None


class AuthMeResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    data: AuthenticatedUser
    error: None = None
    request_id: str = Field(alias="requestId")
