from decimal import Decimal
from uuid import UUID

from app.core.models import ApiModel


class MatchItem(ApiModel):
    id: UUID
    demand_id: UUID
    listing_id: UUID
    score: Decimal
    reasons: list[dict]
    status: str
    commodity: str
    quantity_available: Decimal
    unit: str
    price_per_unit: Decimal
    buyer_name: str
    seller_name: str
