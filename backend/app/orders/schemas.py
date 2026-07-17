from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from app.core.models import ApiModel


class OrderItem(ApiModel):
    id: UUID
    order_number: str
    buyer_organization_id: UUID
    buyer_name: str
    seller_organization_id: UUID
    seller_name: str
    demand_id: UUID | None
    listing_id: UUID
    commodity: str
    quantity: Decimal
    unit: str
    unit_price: Decimal
    subtotal: Decimal
    delivery_fee: Decimal
    total_amount: Decimal
    delivery_method: str
    delivery_date: date
    delivery_address: str | None
    status: str
    created_at: datetime
    updated_at: datetime


class OrderCreateCommand(ApiModel):
    listing_id: UUID
    demand_id: UUID | None = None
    quantity: Decimal
    delivery_method: str
    delivery_date: date
    idempotency_key: str


class OrderControlCommand(ApiModel):
    action: str
    reason: str | None = None
