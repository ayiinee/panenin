from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import Field

from app.core.models import ApiModel


class DemandCreateRequest(ApiModel):
    commodity: str = Field(min_length=2, max_length=120)
    quantity: Decimal = Field(gt=0, max_digits=14, decimal_places=3)
    unit: str = Field(min_length=1, max_length=20)
    grade_tolerance: list[str] = Field(default_factory=list, max_length=10)
    max_price: Decimal = Field(ge=0, max_digits=16, decimal_places=2)
    needed_at: datetime
    delivery_address: str | None = Field(default=None, max_length=500)
    delivery_latitude: float | None = Field(default=None, ge=-90, le=90)
    delivery_longitude: float | None = Field(default=None, ge=-180, le=180)


class DemandItem(ApiModel):
    id: UUID
    buyer_organization_id: UUID
    buyer_name: str
    commodity_id: UUID
    commodity: str
    quantity: Decimal
    quantity_remaining: Decimal
    unit: str
    grade_tolerance: list[str]
    max_price: Decimal
    needed_at: datetime
    status: str
    source: str
    created_at: datetime
    updated_at: datetime
