create table public.listings (
  id uuid primary key default gen_random_uuid(),
  inventory_batch_id uuid not null references public.inventory_batches(id),
  listing_type text not null default 'NORMAL' check (listing_type in ('NORMAL', 'RESCUE')),
  price_per_unit numeric(16, 2) not null check (price_per_unit >= 0),
  minimum_order numeric(14, 3) not null check (minimum_order > 0),
  source text not null check (source in ('APP', 'WHATSAPP', 'ADMIN')),
  status text not null default 'DRAFT' check (
    status in ('DRAFT', 'PUBLISHED', 'PAUSED', 'SOLD_OUT', 'EXPIRED', 'ARCHIVED')
  ),
  quantity_listed numeric(14, 3) not null check (quantity_listed > 0),
  quantity_remaining numeric(14, 3) not null,
  unit text not null,
  currency text not null default 'IDR' check (currency = 'IDR'),
  published_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (quantity_remaining >= 0 and quantity_remaining <= quantity_listed),
  check (minimum_order <= quantity_listed),
  check (listing_type <> 'RESCUE' or expires_at is not null)
);

create table public.listing_media (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  storage_path text not null unique,
  media_type text not null check (media_type in ('IMAGE', 'VIDEO')),
  sort_order integer not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now()
);

create table public.demands (
  id uuid primary key default gen_random_uuid(),
  buyer_organization_id uuid not null references public.organizations(id),
  commodity_id uuid not null references public.commodities(id),
  quantity numeric(14, 3) not null check (quantity > 0),
  quantity_remaining numeric(14, 3) not null,
  unit text not null,
  grade_tolerance text[] not null default '{}',
  max_price numeric(16, 2) not null check (max_price >= 0),
  currency text not null default 'IDR' check (currency = 'IDR'),
  needed_at timestamptz not null,
  delivery_address_text text,
  delivery_latitude numeric(9, 6) check (delivery_latitude between -90 and 90),
  delivery_longitude numeric(9, 6) check (delivery_longitude between -180 and 180),
  status text not null default 'DRAFT' check (
    status in ('DRAFT', 'OPEN', 'PARTIALLY_MATCHED', 'MATCHED', 'FULFILLED', 'EXPIRED', 'CANCELLED')
  ),
  source text not null check (source in ('APP', 'WHATSAPP', 'ADMIN')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (quantity_remaining >= 0 and quantity_remaining <= quantity)
);

create function public.validate_listing()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  batch_unit text;
  batch_available numeric(14, 3);
begin
  select b.unit, b.quantity_available
  into batch_unit, batch_available
  from public.inventory_batches b where b.id = new.inventory_batch_id;

  if batch_unit is distinct from new.unit then
    raise exception 'listing unit must match inventory batch unit';
  end if;
  if (tg_op = 'INSERT'
      or new.inventory_batch_id is distinct from old.inventory_batch_id
      or new.quantity_listed is distinct from old.quantity_listed)
     and new.quantity_listed > batch_available then
    raise exception 'listing quantity exceeds available inventory';
  end if;
  return new;
end;
$$;

create function public.validate_demand()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  organization_type text;
  canonical_unit text;
begin
  select o.type into organization_type
  from public.organizations o where o.id = new.buyer_organization_id;
  if organization_type is distinct from 'UMKM' then
    raise exception 'demand organization must be an UMKM';
  end if;

  select c.default_unit into canonical_unit
  from public.commodities c where c.id = new.commodity_id;
  if canonical_unit is distinct from new.unit then
    raise exception 'demand unit must match commodity default unit';
  end if;
  return new;
end;
$$;

create trigger listings_validate before insert or update on public.listings
for each row execute function public.validate_listing();
create trigger demands_validate before insert or update on public.demands
for each row execute function public.validate_demand();
create trigger listings_set_updated_at before update on public.listings
for each row execute function public.set_updated_at();
create trigger demands_set_updated_at before update on public.demands
for each row execute function public.set_updated_at();
