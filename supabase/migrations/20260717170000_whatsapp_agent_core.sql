create table public.organization_commodities (
  organization_id uuid not null references public.organizations(id) on delete cascade,
  commodity_id uuid not null references public.commodities(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (organization_id, commodity_id)
);

create index organization_commodities_commodity_idx
on public.organization_commodities(commodity_id, organization_id);

create table public.whatsapp_link_codes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  code_hash text not null unique check (code_hash ~ '^[0-9a-f]{64}$'),
  expires_at timestamptz not null,
  consumed_at timestamptz,
  failed_attempts integer not null default 0 check (failed_attempts between 0 and 5),
  created_at timestamptz not null default now(),
  check (expires_at > created_at),
  check (expires_at <= created_at + interval '10 minutes'),
  check (consumed_at is null or consumed_at >= created_at)
);

create unique index whatsapp_link_codes_one_active_per_user_idx
on public.whatsapp_link_codes(user_id)
where consumed_at is null;

create index whatsapp_link_codes_expiry_idx
on public.whatsapp_link_codes(expires_at)
where consumed_at is null;

alter table public.bot_actions
  add column confirmation_code_hash text,
  add column expires_at timestamptz,
  add column confirmed_at timestamptz,
  add column cancelled_at timestamptz,
  add column expected_version text,
  add column channel_subject text,
  add column payload_hash text;

alter table public.bot_actions
  add constraint bot_actions_confirmation_code_hash_format
    check (confirmation_code_hash is null or confirmation_code_hash ~ '^[0-9a-f]{64}$') not valid,
  add constraint bot_actions_payload_hash_format
    check (payload_hash is null or payload_hash ~ '^[0-9a-f]{64}$') not valid,
  add constraint bot_actions_channel_subject_format
    check (channel_subject is null or channel_subject ~ '^wa:v1:[0-9a-f]{16,128}$') not valid,
  add constraint bot_actions_confirmation_timestamps
    check (confirmed_at is null or cancelled_at is null) not valid;

create index bot_actions_channel_pending_idx
on public.bot_actions(channel_subject, expires_at)
where confirmation_status = 'PENDING';

alter table public.user_channels
  add constraint user_channels_whatsapp_subject_format
  check (
    channel_type <> 'WHATSAPP'
    or channel_identifier ~ '^wa:v1:[0-9a-f]{16,128}$'
  ) not valid;

alter table public.organization_commodities enable row level security;
alter table public.whatsapp_link_codes enable row level security;

revoke all on table public.organization_commodities, public.whatsapp_link_codes
from anon, authenticated;

grant all privileges on table
  public.organization_commodities,
  public.whatsapp_link_codes
to service_role;

comment on table public.whatsapp_link_codes is
'One-time, HMAC-hashed codes used to link a Supabase user to a WhatsApp channel subject.';

comment on column public.user_channels.channel_identifier is
'Opaque WhatsApp subject in the form wa:v1:<hex>; raw phone numbers are forbidden.';
