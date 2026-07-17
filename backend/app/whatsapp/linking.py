import json
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.errors import ConflictError, NotFoundError
from app.core.security import (
    generate_confirmation_code,
    hash_one_time_code,
    verify_one_time_code,
)
from app.organizations.repository import OrganizationRepository
from app.whatsapp.schemas import LinkCodeResponse, WhatsAppStatusResponse


class WhatsAppLinkingService:
    def __init__(self) -> None:
        self._organizations = OrganizationRepository()

    async def create_link_code(
        self,
        session: AsyncSession,
        user_id: UUID,
        *,
        request_id: str,
    ) -> LinkCodeResponse:
        settings = get_settings()
        ttl = min(settings.whatsapp_link_code_ttl_seconds, 600)
        code = generate_confirmation_code()
        code_hash = hash_one_time_code(
            code,
            settings.confirmation_code_pepper.get_secret_value(),
        )
        expires_at = datetime.now(UTC) + timedelta(seconds=ttl)
        async with session.begin():
            organization = await self._organizations.get_owned_organization(
                session,
                user_id,
                for_update=True,
            )
            if organization is None:
                raise NotFoundError("Lengkapi profil sebelum menghubungkan WhatsApp.")
            await session.execute(
                text(
                    """
                    update public.whatsapp_link_codes
                    set consumed_at = coalesce(consumed_at, now())
                    where user_id = :user_id and consumed_at is null
                    """
                ),
                {"user_id": user_id},
            )
            await session.execute(
                text(
                    """
                    insert into public.whatsapp_link_codes (
                      user_id, organization_id, code_hash, expires_at
                    ) values (
                      :user_id, :organization_id, :code_hash, :expires_at
                    )
                    """
                ),
                {
                    "user_id": user_id,
                    "organization_id": organization.id,
                    "code_hash": code_hash,
                    "expires_at": expires_at,
                },
            )
            await self._audit(
                session,
                user_id=user_id,
                organization_id=organization.id,
                action="CREATE_WHATSAPP_LINK_CODE",
                source="APP",
                request_id=request_id,
            )
        return LinkCodeResponse(
            link_code=code,
            expires_at=expires_at,
            instruction=f"Kirim HUBUNGKAN {code} melalui WhatsApp.",
        )

    async def status(
        self,
        session: AsyncSession,
        user_id: UUID,
    ) -> WhatsAppStatusResponse:
        row = (
            await session.execute(
                text(
                    """
                    select verified_at
                    from public.user_channels
                    where user_id = :user_id
                      and channel_type = 'WHATSAPP'
                      and is_active
                      and verified_at is not null
                    order by verified_at desc
                    limit 1
                    """
                ),
                {"user_id": user_id},
            )
        ).mappings().first()
        return WhatsAppStatusResponse(
            linked=row is not None,
            verified_at=row["verified_at"] if row else None,
        )

    async def resolve_identity(
        self,
        session: AsyncSession,
        channel_subject: str,
    ) -> dict[str, Any]:
        row = (
            await session.execute(
                text(
                    """
                    select uc.user_id, o.id as organization_id, o.type,
                           o.name, uc.verified_at
                    from public.user_channels uc
                    join public.organizations o on o.owner_user_id = uc.user_id
                    join public.users u on u.id = uc.user_id
                    where uc.channel_type = 'WHATSAPP'
                      and uc.channel_identifier = :subject
                      and uc.is_active and uc.verified_at is not null
                      and o.status = 'ACTIVE' and u.status = 'ACTIVE'
                    order by o.created_at
                    limit 1
                    """
                ),
                {"subject": channel_subject},
            )
        ).mappings().first()
        if row is None:
            return {"linked": False}
        return {
            "linked": True,
            "userId": str(row["user_id"]),
            "organizationId": str(row["organization_id"]),
            "organizationType": row["type"],
            "organizationName": row["name"],
        }

    async def link_identity(
        self,
        session: AsyncSession,
        *,
        channel_subject: str,
        link_code: str,
        request_id: str,
    ) -> dict[str, Any]:
        settings = get_settings()
        pepper = settings.confirmation_code_pepper.get_secret_value()
        candidate_hash = hash_one_time_code(link_code, pepper)
        async with session.begin():
            row = (
                await session.execute(
                    text(
                        """
                        select * from public.whatsapp_link_codes
                        where code_hash = :code_hash
                        for update
                        """
                    ),
                    {"code_hash": candidate_hash},
                )
            ).mappings().first()
            if row is None or not verify_one_time_code(link_code, candidate_hash, pepper):
                raise ConflictError("INVALID_LINK_CODE", "Kode penghubung tidak valid.")
            if row["consumed_at"] is not None:
                raise ConflictError("LINK_CODE_USED", "Kode penghubung sudah digunakan.")
            if row["expires_at"] <= datetime.now(UTC):
                await session.execute(
                    text(
                        "update public.whatsapp_link_codes set failed_attempts = least(5, failed_attempts + 1) where id = :id"
                    ),
                    {"id": row["id"]},
                )
                raise ConflictError("LINK_CODE_EXPIRED", "Kode penghubung sudah kedaluwarsa.")
            if row["failed_attempts"] >= 5:
                raise ConflictError("LINK_CODE_LOCKED", "Kode penghubung tidak dapat digunakan.")

            existing = (
                await session.execute(
                    text(
                        """
                        select user_id from public.user_channels
                        where channel_type = 'WHATSAPP'
                          and channel_identifier = :subject
                        for update
                        """
                    ),
                    {"subject": channel_subject},
                )
            ).mappings().first()
            if existing is not None and existing["user_id"] != row["user_id"]:
                raise ConflictError(
                    "CHANNEL_ALREADY_LINKED",
                    "Identitas WhatsApp sudah terhubung ke akun lain.",
                )
            if existing is None:
                await session.execute(
                    text(
                        """
                        insert into public.user_channels (
                          user_id, channel_type, channel_identifier,
                          verified_at, is_active
                        ) values (
                          :user_id, 'WHATSAPP', :subject, now(), true
                        )
                        """
                    ),
                    {"user_id": row["user_id"], "subject": channel_subject},
                )
            else:
                await session.execute(
                    text(
                        """
                        update public.user_channels
                        set verified_at = now(), is_active = true
                        where channel_type = 'WHATSAPP'
                          and channel_identifier = :subject
                        """
                    ),
                    {"subject": channel_subject},
                )
            await session.execute(
                text(
                    "update public.whatsapp_link_codes set consumed_at = now() where id = :id"
                ),
                {"id": row["id"]},
            )
            await self._audit(
                session,
                user_id=row["user_id"],
                organization_id=row["organization_id"],
                action="LINK_WHATSAPP_IDENTITY",
                source="WHATSAPP",
                request_id=request_id,
            )
        return await self.resolve_identity(session, channel_subject)

    async def _audit(
        self,
        session: AsyncSession,
        *,
        user_id: UUID,
        organization_id: UUID,
        action: str,
        source: str,
        request_id: str,
    ) -> None:
        await session.execute(
            text(
                """
                insert into public.audit_logs (
                  actor_user_id, action, entity_type, entity_id,
                  source, new_data_json, request_id
                ) values (
                  :user_id, :action, 'organization', :organization_id,
                  :source, cast(:data as jsonb), :request_id
                )
                """
            ),
            {
                "user_id": user_id,
                "action": action,
                "organization_id": organization_id,
                "source": source,
                "data": json.dumps({"channel": "WHATSAPP"}),
                "request_id": request_id,
            },
        )
