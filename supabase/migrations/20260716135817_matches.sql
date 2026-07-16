create table public.matches (
  id uuid primary key default gen_random_uuid(),
  demand_id uuid not null references public.demands(id) on delete cascade,
  listing_id uuid not null references public.listings(id) on delete cascade,
  score numeric(5, 4) not null check (score between 0 and 1),
  reasons_json jsonb not null default '[]'::jsonb check (jsonb_typeof(reasons_json) = 'array'),
  status text not null default 'SUGGESTED' check (
    status in ('SUGGESTED', 'VIEWED', 'ACCEPTED', 'REJECTED', 'EXPIRED')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (demand_id, listing_id)
);

create function public.validate_match()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  demand_row public.demands%rowtype;
  listing_row public.listings%rowtype;
  seller_organization_id uuid;
  listing_commodity_id uuid;
begin
  select * into demand_row from public.demands d where d.id = new.demand_id;
  select * into listing_row from public.listings l where l.id = new.listing_id;
  select b.organization_id, b.commodity_id
  into seller_organization_id, listing_commodity_id
  from public.inventory_batches b where b.id = listing_row.inventory_batch_id;

  if demand_row.commodity_id is distinct from listing_commodity_id
     or demand_row.unit is distinct from listing_row.unit then
    raise exception 'match demand and listing must use the same commodity and unit';
  end if;
  if demand_row.buyer_organization_id = seller_organization_id then
    raise exception 'an organization cannot match its own listing';
  end if;
  if new.status in ('SUGGESTED', 'VIEWED', 'ACCEPTED') and (
    demand_row.status not in ('OPEN', 'PARTIALLY_MATCHED', 'MATCHED')
    or listing_row.status <> 'PUBLISHED'
  ) then
    raise exception 'match requires an active demand and published listing';
  end if;
  return new;
end;
$$;

create trigger matches_validate before insert or update on public.matches
for each row execute function public.validate_match();
create trigger matches_set_updated_at before update on public.matches
for each row execute function public.set_updated_at();
