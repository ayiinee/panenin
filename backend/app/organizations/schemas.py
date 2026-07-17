from typing import Literal
from uuid import UUID

from pydantic import Field

from app.core.models import ApiModel


class ProfileUpsertRequest(ApiModel):
    name: str = Field(min_length=2, max_length=120)
    organization_name: str = Field(min_length=2, max_length=160)
    organization_type: Literal["FARM", "UMKM"]
    address: str = Field(min_length=3, max_length=500)
    commodity_names: list[str] = Field(min_length=1, max_length=30)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)


class ProfileResponse(ApiModel):
    user_id: UUID
    name: str
    organization_id: UUID
    organization_name: str
    organization_type: Literal["FARM", "UMKM"]
    address: str | None
    latitude: float | None
    longitude: float | None
    commodity_names: list[str]
