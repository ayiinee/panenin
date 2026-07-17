from datetime import datetime
from typing import Literal

from pydantic import Field

from app.core.models import ApiModel


class LinkCodeResponse(ApiModel):
    link_code: str
    expires_at: datetime
    instruction: str


class WhatsAppStatusResponse(ApiModel):
    linked: bool
    channel: Literal["WHATSAPP"] = "WHATSAPP"
    verified_at: datetime | None = None


class IdentityResolveRequest(ApiModel):
    channel: Literal["WHATSAPP"]
    channel_subject: str = Field(pattern=r"^wa:v1:[0-9a-f]{16,128}$")


class IdentityLinkRequest(IdentityResolveRequest):
    link_code: str = Field(min_length=6, max_length=12, pattern=r"^[A-Za-z0-9]+$")
