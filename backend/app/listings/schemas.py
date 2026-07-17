from datetime import datetime
from decimal import Decimal
from uuid import UUID

from app.core.models import ApiModel


class ListingItem(ApiModel):
    id: UUID
    inventory_batch_id: UUID
    seller_organization_id: UUID
    seller_name: str
    commodity_id: UUID
    commodity: str
    listing_type: str
    price_per_unit: Decimal
    minimum_order: Decimal
    quantity_remaining: Decimal
    unit: str
    status: str
    available_at: datetime
    grade: str | None
    published_at: datetime | None
    expires_at: datetime | None
    updated_at: datetime
