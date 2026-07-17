import json
from decimal import Decimal
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import AuthorizationError, ConflictError, NotFoundError
from app.inventory.repository import InventoryRepository
from app.inventory.schemas import (
    InventoryCreateRequest,
    InventoryItem,
    InventoryPatchRequest,
)
from app.organizations.repository import OrganizationRepository


class InventoryService:
    def __init__(
        self,
        repository: InventoryRepository | None = None,
        organizations: OrganizationRepository | None = None,
    ) -> None:
        self._repository = repository or InventoryRepository()
        self._organizations = organizations or OrganizationRepository()

    async def list_inventory(
        self,
        session: AsyncSession,
        user_id: UUID,
    ) -> list[InventoryItem]:
        organization = await self._organizations.get_owned_organization(session, user_id)
        if organization is None:
            raise NotFoundError("Profil organisasi belum dilengkapi.")
        rows = await self._repository.list_for_organization(session, organization.id)
        return [InventoryItem.model_validate(row) for row in rows]

    async def create_inventory(
        self,
        session: AsyncSession,
        user_id: UUID,
        payload: InventoryCreateRequest,
        *,
        request_id: str,
    ) -> InventoryItem:
        async with session.begin():
            organization = await self._organizations.get_owned_organization(
                session,
                user_id,
                for_update=True,
            )
            if organization is None:
                raise NotFoundError("Profil organisasi belum dilengkapi.")
            if organization.type != "FARM":
                raise AuthorizationError("Hanya organisasi FARM dapat mengelola stok.")
            commodity = (
                await session.execute(
                    text(
                        """
                        select id, name, default_unit
                        from public.commodities
                        where is_active and lower(name) = lower(:name)
                        """
                    ),
                    {"name": payload.commodity},
                )
            ).mappings().first()
            if commodity is None:
                raise NotFoundError("Komoditas tidak ditemukan.")
            if commodity["default_unit"].casefold() != payload.unit.casefold():
                raise ConflictError(
                    "UNIT_MISMATCH",
                    "Satuan harus mengikuti satuan komoditas.",
                )
            row = (
                await session.execute(
                    text(
                        """
                        insert into public.inventory_batches (
                          organization_id, commodity_id, quantity_total,
                          quantity_available, unit, grade, harvested_at,
                          available_at, minimum_price, status
                        ) values (
                          :organization_id, :commodity_id, :quantity,
                          :quantity, :unit, :grade, :harvested_at,
                          :available_at, :minimum_price, 'AVAILABLE'
                        ) returning *
                        """
                    ),
                    {
                        "organization_id": organization.id,
                        "commodity_id": commodity["id"],
                        "quantity": payload.quantity,
                        "unit": commodity["default_unit"],
                        "grade": payload.grade,
                        "harvested_at": payload.harvested_at,
                        "available_at": payload.available_at,
                        "minimum_price": payload.minimum_price,
                    },
                )
            ).mappings().one()
            await session.execute(
                text(
                    """
                    insert into public.inventory_movements (
                      inventory_batch_id, movement_type, quantity,
                      quantity_before, quantity_after, actor_user_id, notes
                    ) values (
                      :batch_id, 'STOCK_IN', :quantity, 0, :quantity,
                      :user_id, 'Created through Panenin Core mobile API'
                    )
                    """
                ),
                {"batch_id": row["id"], "quantity": payload.quantity, "user_id": user_id},
            )
            await self._write_audit(
                session,
                user_id=user_id,
                action="CREATE_INVENTORY",
                entity_id=row["id"],
                request_id=request_id,
                data={"commodityId": str(commodity["id"]), "quantity": str(payload.quantity)},
            )
        return InventoryItem.model_validate(
            {**dict(row), "commodity": commodity["name"], "quantity_reserved": 0}
        )

    async def patch_inventory(
        self,
        session: AsyncSession,
        user_id: UUID,
        batch_id: UUID,
        payload: InventoryPatchRequest,
        *,
        request_id: str,
    ) -> InventoryItem:
        async with session.begin():
            organization = await self._organizations.get_owned_organization(
                session,
                user_id,
                for_update=True,
            )
            if organization is None or organization.type != "FARM":
                raise AuthorizationError("Hanya organisasi FARM dapat mengelola stok.")
            batch = await self._repository.get_batch(session, batch_id, for_update=True)
            if batch is None:
                raise NotFoundError("Batch stok tidak ditemukan.")
            if batch["organization_id"] != organization.id:
                raise AuthorizationError()

            old_available = Decimal(batch["quantity_available"])
            new_available = payload.quantity_available
            new_total = Decimal(batch["quantity_total"])
            movement_quantity: Decimal | None = None
            if new_available is not None and new_available != old_available:
                delta = new_available - old_available
                new_total += delta
                if new_total <= 0:
                    raise ConflictError("INVALID_QUANTITY", "Total stok harus lebih dari nol.")
                movement_quantity = abs(delta)

            status = payload.status or batch["status"]
            if new_available == 0 and status == "AVAILABLE":
                status = "SOLD_OUT"
            elif new_available is not None and new_available > 0 and status == "SOLD_OUT":
                status = "AVAILABLE"

            updated = (
                await session.execute(
                    text(
                        """
                        update public.inventory_batches
                        set quantity_total = :quantity_total,
                            quantity_available = :quantity_available,
                            grade = :grade,
                            minimum_price = :minimum_price,
                            status = :status
                        where id = :batch_id
                        returning *
                        """
                    ),
                    {
                        "quantity_total": new_total,
                        "quantity_available": new_available
                        if new_available is not None
                        else old_available,
                        "grade": payload.grade if "grade" in payload.model_fields_set else batch["grade"],
                        "minimum_price": payload.minimum_price
                        if payload.minimum_price is not None
                        else batch["minimum_price"],
                        "status": status,
                        "batch_id": batch_id,
                    },
                )
            ).mappings().one()
            if movement_quantity is not None:
                await session.execute(
                    text(
                        """
                        insert into public.inventory_movements (
                          inventory_batch_id, movement_type, quantity,
                          quantity_before, quantity_after, actor_user_id, notes
                        ) values (
                          :batch_id, 'ADJUSTMENT', :quantity,
                          :before, :after, :user_id,
                          'Adjusted through Panenin Core mobile API'
                        )
                        """
                    ),
                    {
                        "batch_id": batch_id,
                        "quantity": movement_quantity,
                        "before": old_available,
                        "after": new_available,
                        "user_id": user_id,
                    },
                )
            await self._write_audit(
                session,
                user_id=user_id,
                action="UPDATE_INVENTORY",
                entity_id=batch_id,
                request_id=request_id,
                data={"quantityAvailable": str(updated["quantity_available"]), "status": status},
            )
        return InventoryItem.model_validate(
            {**dict(updated), "commodity": batch["commodity"], "quantity_reserved": 0}
        )

    async def _write_audit(
        self,
        session: AsyncSession,
        *,
        user_id: UUID,
        action: str,
        entity_id: UUID,
        request_id: str,
        data: dict,
    ) -> None:
        await session.execute(
            text(
                """
                insert into public.audit_logs (
                  actor_user_id, action, entity_type, entity_id,
                  source, new_data_json, request_id
                ) values (
                  :user_id, :action, 'inventory_batch', :entity_id,
                  'APP', cast(:data as jsonb), :request_id
                )
                """
            ),
            {
                "user_id": user_id,
                "action": action,
                "entity_id": entity_id,
                "data": json.dumps(data, separators=(",", ":")),
                "request_id": request_id,
            },
        )
