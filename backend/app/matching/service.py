import json
from decimal import Decimal
from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.demands.repository import DemandRepository
from app.listings.repository import ListingRepository


def deterministic_match(
    *,
    requested_quantity: Decimal,
    candidate_quantity: Decimal,
    max_price: Decimal,
    listing_price: Decimal,
    grade_required: list[str],
    listing_grade: str | None,
) -> tuple[Decimal, list[dict[str, Any]]]:
    coverage = min(candidate_quantity / requested_quantity, Decimal("1"))
    if max_price > 0:
        price_ratio = max(Decimal("0"), Decimal("1") - listing_price / max_price)
    else:
        price_ratio = Decimal("1") if listing_price == 0 else Decimal("0")
    grade_score = Decimal("1")
    if grade_required:
        grade_score = Decimal("1") if listing_grade and listing_grade.upper() in {
            value.upper() for value in grade_required
        } else Decimal("0.5")
    score = (
        Decimal("0.35")
        + Decimal("0.20") * coverage
        + Decimal("0.20") * price_ratio
        + Decimal("0.10")
        + Decimal("0.10") * grade_score
    )
    score = min(Decimal("1"), score.quantize(Decimal("0.0001")))
    reasons = [
        {"code": "COMMODITY_EXACT", "weight": 0.25},
        {"code": "UNIT_EXACT", "weight": 0.10},
        {"code": "PRICE_WITHIN_LIMIT", "savingRatio": float(price_ratio)},
        {"code": "AVAILABLE_BEFORE_NEEDED", "weight": 0.10},
        {"code": "QUANTITY_COVERAGE", "coverage": float(coverage)},
        {"code": "GRADE_COMPATIBLE", "score": float(grade_score)},
    ]
    return score, reasons


class MatchingService:
    def __init__(
        self,
        listings: ListingRepository | None = None,
        demands: DemandRepository | None = None,
    ) -> None:
        self._listings = listings or ListingRepository()
        self._demands = demands or DemandRepository()

    async def listing_candidates(
        self,
        session: AsyncSession,
        *,
        commodity: str,
        quantity: Decimal,
        unit: str,
        max_price: Decimal,
        needed_at,
        grade_tolerance: list[str],
    ) -> list[dict[str, Any]]:
        rows = await self._listings.search_catalog(
            session,
            commodity=commodity,
            quantity=quantity,
            unit=unit,
            max_price=max_price,
            needed_at=needed_at,
            grade_tolerance=grade_tolerance,
            limit=5,
        )
        return [self._score_listing(row, quantity, max_price, grade_tolerance) for row in rows]

    async def demand_candidates(
        self,
        session: AsyncSession,
        *,
        commodity: str,
        quantity: Decimal,
        unit: str,
        listing_price: Decimal,
        available_at,
        grade: str | None,
        seller_organization_id: UUID,
    ) -> list[dict[str, Any]]:
        rows = await self._demands.candidate_demands(
            session,
            commodity=commodity,
            quantity=quantity,
            unit=unit,
            listing_price=listing_price,
            available_at=available_at,
            grade=grade,
            seller_organization_id=seller_organization_id,
        )
        results = []
        for row in rows:
            score, reasons = deterministic_match(
                requested_quantity=Decimal(row["quantity_remaining"]),
                candidate_quantity=quantity,
                max_price=Decimal(row["max_price"]),
                listing_price=listing_price,
                grade_required=list(row["grade_tolerance"]),
                listing_grade=grade,
            )
            results.append(
                {
                    "demandId": str(row["id"]),
                    "buyerOrganizationId": str(row["buyer_organization_id"]),
                    "buyerName": row["buyer_name"],
                    "quantity": str(row["quantity_remaining"]),
                    "unit": row["unit"],
                    "maxPrice": str(row["max_price"]),
                    "neededAt": row["needed_at"].isoformat(),
                    "score": float(score),
                    "reasons": reasons,
                }
            )
        return results

    async def persist_for_demand(
        self,
        session: AsyncSession,
        demand: dict[str, Any],
    ) -> None:
        candidates = await self._listings.search_catalog(
            session,
            commodity=demand["commodity"],
            quantity=Decimal(demand["quantity_remaining"]),
            unit=demand["unit"],
            max_price=Decimal(demand["max_price"]),
            needed_at=demand["needed_at"],
            grade_tolerance=list(demand["grade_tolerance"]),
            limit=50,
        )
        for listing in candidates:
            scored = self._score_listing(
                listing,
                Decimal(demand["quantity_remaining"]),
                Decimal(demand["max_price"]),
                list(demand["grade_tolerance"]),
            )
            await session.execute(
                text(
                    """
                    insert into public.matches (
                      demand_id, listing_id, score, reasons_json, status
                    ) values (
                      :demand_id, :listing_id, :score,
                      cast(:reasons as jsonb), 'SUGGESTED'
                    )
                    on conflict (demand_id, listing_id) do update set
                      score = excluded.score,
                      reasons_json = excluded.reasons_json,
                      status = 'SUGGESTED'
                    """
                ),
                {
                    "demand_id": demand["id"],
                    "listing_id": listing["id"],
                    "score": scored["score"],
                    "reasons": json.dumps(scored["reasons"], separators=(",", ":")),
                },
            )

    async def persist_for_listing(
        self,
        session: AsyncSession,
        listing: dict[str, Any],
    ) -> None:
        demands = await self._demands.candidate_demands(
            session,
            commodity=listing["commodity"],
            quantity=Decimal(listing["quantity_remaining"]),
            unit=listing["unit"],
            listing_price=Decimal(listing["price_per_unit"]),
            available_at=listing["available_at"],
            grade=listing.get("grade"),
            seller_organization_id=listing["seller_organization_id"],
            limit=50,
        )
        for demand in demands:
            score, reasons = deterministic_match(
                requested_quantity=Decimal(demand["quantity_remaining"]),
                candidate_quantity=Decimal(listing["quantity_remaining"]),
                max_price=Decimal(demand["max_price"]),
                listing_price=Decimal(listing["price_per_unit"]),
                grade_required=list(demand["grade_tolerance"]),
                listing_grade=listing.get("grade"),
            )
            await session.execute(
                text(
                    """
                    insert into public.matches (
                      demand_id, listing_id, score, reasons_json, status
                    ) values (
                      :demand_id, :listing_id, :score,
                      cast(:reasons as jsonb), 'SUGGESTED'
                    )
                    on conflict (demand_id, listing_id) do update set
                      score = excluded.score,
                      reasons_json = excluded.reasons_json,
                      status = 'SUGGESTED'
                    """
                ),
                {
                    "demand_id": demand["id"],
                    "listing_id": listing["id"],
                    "score": score,
                    "reasons": json.dumps(reasons, separators=(",", ":")),
                },
            )

    async def list_for_organization(
        self,
        session: AsyncSession,
        organization_id: UUID,
    ) -> list[dict[str, Any]]:
        rows = (
            await session.execute(
                text(
                    """
                    select m.id, m.demand_id, m.listing_id, m.score,
                           m.reasons_json as reasons, m.status,
                           c.name as commodity, l.quantity_remaining as quantity_available,
                           l.unit, l.price_per_unit, buyer.name as buyer_name,
                           seller.name as seller_name
                    from public.matches m
                    join public.demands d on d.id = m.demand_id
                    join public.organizations buyer on buyer.id = d.buyer_organization_id
                    join public.listings l on l.id = m.listing_id
                    join public.inventory_batches b on b.id = l.inventory_batch_id
                    join public.organizations seller on seller.id = b.organization_id
                    join public.commodities c on c.id = d.commodity_id
                    where d.buyer_organization_id = :organization_id
                       or b.organization_id = :organization_id
                    order by m.score desc, m.created_at desc
                    """
                ),
                {"organization_id": organization_id},
            )
        ).mappings().all()
        return [dict(row) for row in rows]

    def _score_listing(
        self,
        row: dict[str, Any],
        quantity: Decimal,
        max_price: Decimal,
        grades: list[str],
    ) -> dict[str, Any]:
        score, reasons = deterministic_match(
            requested_quantity=quantity,
            candidate_quantity=Decimal(row["quantity_remaining"]),
            max_price=max_price,
            listing_price=Decimal(row["price_per_unit"]),
            grade_required=grades,
            listing_grade=row.get("grade"),
        )
        return {
            "listingId": str(row["id"]),
            "sellerOrganizationId": str(row["seller_organization_id"]),
            "sellerName": row["seller_name"],
            "commodity": row["commodity"],
            "quantity": str(row["quantity_remaining"]),
            "unit": row["unit"],
            "pricePerUnit": str(row["price_per_unit"]),
            "availableAt": row["available_at"].isoformat(),
            "grade": row.get("grade"),
            "score": float(score),
            "reasons": reasons,
        }
