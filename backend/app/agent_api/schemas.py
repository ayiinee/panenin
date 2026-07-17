from datetime import date, datetime
from decimal import Decimal
from typing import Literal
from uuid import UUID

from pydantic import Field, model_validator

from app.core.models import ApiModel
from app.whatsapp.schemas import IdentityLinkRequest, IdentityResolveRequest

ChannelSubject = str


class CatalogSearchRequest(ApiModel):
    channel_subject: str = Field(pattern=r"^wa:v1:[0-9a-f]{16,128}$")
    commodity: str = Field(min_length=2, max_length=120)
    quantity: Decimal = Field(gt=0, max_digits=14, decimal_places=3)
    unit: str = Field(min_length=1, max_length=20)
    max_price: Decimal = Field(ge=0, max_digits=16, decimal_places=2)
    needed_at: datetime


class SellPreviewRequest(ApiModel):
    channel_subject: str = Field(pattern=r"^wa:v1:[0-9a-f]{16,128}$")
    commodity: str = Field(min_length=2, max_length=120)
    quantity: Decimal = Field(gt=0, max_digits=14, decimal_places=3)
    unit: str = Field(min_length=1, max_length=20)
    grade: str | None = Field(default=None, max_length=30)
    harvested_at: datetime | None = None
    available_at: datetime
    minimum_price: Decimal = Field(ge=0, max_digits=16, decimal_places=2)
    listing_price: Decimal = Field(ge=0, max_digits=16, decimal_places=2)
    minimum_order: Decimal = Field(gt=0, max_digits=14, decimal_places=3)
    listing_type: Literal["NORMAL", "RESCUE"]

    @model_validator(mode="after")
    def validate_prices_and_quantity(self) -> "SellPreviewRequest":
        if self.listing_price < self.minimum_price:
            raise ValueError("Harga listing tidak boleh di bawah harga minimum.")
        if self.minimum_order > self.quantity:
            raise ValueError("Minimum order tidak boleh melebihi jumlah stok.")
        return self


class BuyPreviewRequest(ApiModel):
    channel_subject: str = Field(pattern=r"^wa:v1:[0-9a-f]{16,128}$")
    commodity: str = Field(min_length=2, max_length=120)
    quantity: Decimal = Field(gt=0, max_digits=14, decimal_places=3)
    unit: str = Field(min_length=1, max_length=20)
    grade_tolerance: list[str] = Field(default_factory=list, max_length=10)
    max_price: Decimal = Field(ge=0, max_digits=16, decimal_places=2)
    needed_at: datetime
    delivery_method: Literal["PICKUP", "SELLER_DELIVERY", "THIRD_PARTY"]


class OrderPreviewRequest(ApiModel):
    channel_subject: str = Field(pattern=r"^wa:v1:[0-9a-f]{16,128}$")
    listing_id: UUID
    demand_id: UUID | None = None
    quantity: Decimal = Field(gt=0, max_digits=14, decimal_places=3)
    delivery_method: Literal["PICKUP", "SELLER_DELIVERY", "THIRD_PARTY"]
    delivery_date: date


class ControlPreviewRequest(ApiModel):
    channel_subject: str = Field(pattern=r"^wa:v1:[0-9a-f]{16,128}$")
    action: Literal[
        "ACCEPT_ORDER",
        "REJECT_ORDER",
        "MARK_ORDER_READY",
        "CANCEL_ORDER",
        "COMPLETE_ORDER",
        "PAUSE_LISTING",
        "PUBLISH_LISTING",
        "ADJUST_INVENTORY",
    ]
    target_id: UUID
    reason: str | None = Field(default=None, max_length=300)
    quantity: Decimal | None = Field(default=None, ge=0, max_digits=14, decimal_places=3)

    @model_validator(mode="after")
    def require_adjustment_quantity(self) -> "ControlPreviewRequest":
        if self.action == "ADJUST_INVENTORY" and self.quantity is None:
            raise ValueError("Jumlah diperlukan untuk penyesuaian stok.")
        return self


class ConfirmActionRequest(ApiModel):
    channel_subject: str = Field(pattern=r"^wa:v1:[0-9a-f]{16,128}$")
    confirmation_code: str = Field(min_length=6, max_length=12, pattern=r"^[A-Za-z0-9]+$")
    idempotency_key: str = Field(min_length=36, max_length=36)


class CancelActionRequest(ApiModel):
    channel_subject: str = Field(pattern=r"^wa:v1:[0-9a-f]{16,128}$")


class PreviewResponse(ApiModel):
    action_id: UUID
    confirmation_code: str
    expires_at: datetime
    summary: dict
    candidate_demands: list[dict] | None = None
    candidate_listings: list[dict] | None = None
