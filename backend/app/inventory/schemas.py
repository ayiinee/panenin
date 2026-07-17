from datetime import datetime
from decimal import Decimal
from typing import Literal
from uuid import UUID

from pydantic import Field, model_validator

from app.core.models import ApiModel


class InventoryCreateRequest(ApiModel):
    commodity: str = Field(min_length=2, max_length=120)
    quantity: Decimal = Field(gt=0, max_digits=14, decimal_places=3)
    unit: str = Field(min_length=1, max_length=20)
    grade: str | None = Field(default=None, max_length=30)
    harvested_at: datetime | None = None
    available_at: datetime
    minimum_price: Decimal = Field(ge=0, max_digits=16, decimal_places=2)


class InventoryPatchRequest(ApiModel):
    quantity_available: Decimal | None = Field(
        default=None,
        ge=0,
        max_digits=14,
        decimal_places=3,
    )
    grade: str | None = Field(default=None, max_length=30)
    minimum_price: Decimal | None = Field(
        default=None,
        ge=0,
        max_digits=16,
        decimal_places=2,
    )
    status: Literal["AVAILABLE", "INACTIVE"] | None = None

    @model_validator(mode="after")
    def at_least_one_change(self) -> "InventoryPatchRequest":
        if not self.model_fields_set:
            raise ValueError("Minimal satu perubahan diperlukan.")
        return self


class InventoryItem(ApiModel):
    id: UUID
    organization_id: UUID
    commodity_id: UUID
    commodity: str
    quantity_total: Decimal
    quantity_available: Decimal
    quantity_reserved: Decimal
    unit: str
    grade: str | None
    harvested_at: datetime | None
    available_at: datetime
    minimum_price: Decimal
    status: str
    updated_at: datetime
