create table public.commodities (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  category text not null,
  default_unit text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.inventory_batches (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  commodity_id uuid not null references public.commodities(id),
  quantity_total numeric(14, 3) not null check (quantity_total > 0),
  quantity_available numeric(14, 3) not null check (
    quantity_available >= 0 and quantity_available <= quantity_total
  ),
  unit text not null,
  grade text,
  harvested_at timestamptz,
  available_at timestamptz not null,
  minimum_price numeric(16, 2) not null default 0 check (minimum_price >= 0),
  currency text not null default 'IDR' check (currency = 'IDR'),
  status text not null default 'AVAILABLE' check (
    status in ('AVAILABLE', 'PARTIALLY_RESERVED', 'SOLD_OUT', 'EXPIRED', 'INACTIVE')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  inventory_batch_id uuid not null references public.inventory_batches(id),
  movement_type text not null check (
    movement_type in ('STOCK_IN', 'RESERVE', 'RELEASE', 'SOLD', 'ADJUSTMENT')
  ),
  quantity numeric(14, 3) not null check (quantity > 0),
  quantity_before numeric(14, 3) not null check (quantity_before >= 0),
  quantity_after numeric(14, 3) not null check (quantity_after >= 0),
  reference_type text,
  reference_id uuid,
  actor_user_id uuid references public.users(id) on delete set null,
  notes text,
  created_at timestamptz not null default now()
);

create function public.validate_inventory_batch()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  organization_type text;
  canonical_unit text;
begin
  select o.type into organization_type
  from public.organizations o where o.id = new.organization_id;
  if organization_type is distinct from 'FARM' then
    raise exception 'inventory batch organization must be a FARM';
  end if;

  select c.default_unit into canonical_unit
  from public.commodities c where c.id = new.commodity_id;
  if canonical_unit is distinct from new.unit then
    raise exception 'inventory unit must match commodity default unit';
  end if;
  return new;
end;
$$;

create trigger inventory_batches_validate
before insert or update on public.inventory_batches
for each row execute function public.validate_inventory_batch();

create trigger commodities_set_updated_at before update on public.commodities
for each row execute function public.set_updated_at();
create trigger inventory_batches_set_updated_at before update on public.inventory_batches
for each row execute function public.set_updated_at();
