create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  idempotency_key text not null unique,
  buyer_organization_id uuid not null references public.organizations(id),
  seller_organization_id uuid not null references public.organizations(id),
  demand_id uuid references public.demands(id),
  listing_id uuid not null references public.listings(id),
  quantity numeric(14, 3) not null check (quantity > 0),
  unit text not null,
  unit_price numeric(16, 2) not null check (unit_price >= 0),
  subtotal numeric(16, 2) not null check (subtotal >= 0),
  delivery_fee numeric(16, 2) not null default 0 check (delivery_fee >= 0),
  total_amount numeric(16, 2) not null check (total_amount >= 0),
  currency text not null default 'IDR' check (currency = 'IDR'),
  delivery_method text not null check (
    delivery_method in ('PICKUP', 'SELLER_DELIVERY', 'THIRD_PARTY')
  ),
  delivery_date date not null,
  delivery_address_text text,
  delivery_latitude numeric(9, 6) check (delivery_latitude between -90 and 90),
  delivery_longitude numeric(9, 6) check (delivery_longitude between -180 and 180),
  status text not null default 'PENDING_SELLER' check (
    status in ('DRAFT', 'PENDING_SELLER', 'ACCEPTED', 'READY', 'PICKED_UP', 'DELIVERED', 'COMPLETED', 'REJECTED', 'CANCELLED', 'DISPUTED')
  ),
  rejection_reason text,
  cancellation_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  accepted_at timestamptz,
  ready_at timestamptz,
  picked_up_at timestamptz,
  delivered_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  check (buyer_organization_id <> seller_organization_id),
  check (subtotal = round(quantity * unit_price, 2)),
  check (total_amount = subtotal + delivery_fee)
);

create table public.inventory_reservations (
  id uuid primary key default gen_random_uuid(),
  inventory_batch_id uuid not null references public.inventory_batches(id),
  order_id uuid not null references public.orders(id),
  quantity numeric(14, 3) not null check (quantity > 0),
  status text not null default 'ACTIVE' check (
    status in ('ACTIVE', 'RELEASED', 'CONSUMED', 'EXPIRED')
  ),
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id),
  old_status text,
  new_status text not null,
  actor_user_id uuid references public.users(id) on delete set null,
  source text not null check (source in ('APP', 'WHATSAPP', 'ADMIN', 'SYSTEM')),
  notes text,
  created_at timestamptz not null default now(),
  check (old_status is null or old_status in ('DRAFT', 'PENDING_SELLER', 'ACCEPTED', 'READY', 'PICKED_UP', 'DELIVERED', 'COMPLETED', 'REJECTED', 'CANCELLED', 'DISPUTED')),
  check (new_status in ('DRAFT', 'PENDING_SELLER', 'ACCEPTED', 'READY', 'PICKED_UP', 'DELIVERED', 'COMPLETED', 'REJECTED', 'CANCELLED', 'DISPUTED'))
);

create function public.validate_order()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  buyer_type text;
  seller_type text;
  listing_row public.listings%rowtype;
  listing_seller_id uuid;
  listing_commodity_id uuid;
  demand_row public.demands%rowtype;
begin
  select o.type into buyer_type from public.organizations o where o.id = new.buyer_organization_id;
  select o.type into seller_type from public.organizations o where o.id = new.seller_organization_id;
  if buyer_type is distinct from 'UMKM' or seller_type is distinct from 'FARM' then
    raise exception 'order buyer must be UMKM and seller must be FARM';
  end if;

  select * into listing_row from public.listings l where l.id = new.listing_id;
  select b.organization_id, b.commodity_id
  into listing_seller_id, listing_commodity_id
  from public.inventory_batches b where b.id = listing_row.inventory_batch_id;
  if listing_seller_id is distinct from new.seller_organization_id
     or listing_row.unit is distinct from new.unit then
    raise exception 'order seller and unit must match the listing';
  end if;
  if tg_op = 'INSERT' and (
    listing_row.status <> 'PUBLISHED' or new.quantity > listing_row.quantity_remaining
  ) then
    raise exception 'order requires sufficient quantity on a published listing';
  end if;

  if new.demand_id is not null then
    select * into demand_row from public.demands d where d.id = new.demand_id;
    if demand_row.buyer_organization_id is distinct from new.buyer_organization_id
       or demand_row.commodity_id is distinct from listing_commodity_id
       or demand_row.unit is distinct from new.unit then
      raise exception 'order demand must match buyer, commodity, and unit';
    end if;
  end if;
  return new;
end;
$$;

create function public.validate_order_status_transition()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.status = new.status then
    return new;
  end if;

  if not (
    (old.status = 'DRAFT' and new.status in ('PENDING_SELLER', 'CANCELLED'))
    or (old.status = 'PENDING_SELLER' and new.status in ('ACCEPTED', 'REJECTED', 'CANCELLED'))
    or (old.status = 'ACCEPTED' and new.status in ('READY', 'CANCELLED'))
    or (old.status = 'READY' and new.status in ('PICKED_UP', 'CANCELLED'))
    or (old.status = 'PICKED_UP' and new.status = 'DELIVERED')
    or (old.status = 'DELIVERED' and new.status in ('COMPLETED', 'DISPUTED'))
    or (old.status = 'DISPUTED' and new.status in ('COMPLETED', 'CANCELLED'))
  ) then
    raise exception 'invalid order status transition: % -> %', old.status, new.status;
  end if;

  new.accepted_at = case when new.status = 'ACCEPTED' then coalesce(new.accepted_at, now()) else new.accepted_at end;
  new.ready_at = case when new.status = 'READY' then coalesce(new.ready_at, now()) else new.ready_at end;
  new.picked_up_at = case when new.status = 'PICKED_UP' then coalesce(new.picked_up_at, now()) else new.picked_up_at end;
  new.delivered_at = case when new.status = 'DELIVERED' then coalesce(new.delivered_at, now()) else new.delivered_at end;
  new.completed_at = case when new.status = 'COMPLETED' then coalesce(new.completed_at, now()) else new.completed_at end;
  new.cancelled_at = case when new.status = 'CANCELLED' then coalesce(new.cancelled_at, now()) else new.cancelled_at end;
  return new;
end;
$$;

create function public.record_order_status_history()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  action_source text := upper(coalesce(nullif(current_setting('app.action_source', true), ''), 'SYSTEM'));
  actor_id uuid;
begin
  if action_source not in ('APP', 'WHATSAPP', 'ADMIN', 'SYSTEM') then
    action_source := 'SYSTEM';
  end if;
  begin
    actor_id := nullif(current_setting('app.actor_user_id', true), '')::uuid;
  exception when invalid_text_representation then
    actor_id := null;
  end;

  insert into public.order_status_history (order_id, old_status, new_status, actor_user_id, source)
  values (new.id, case when tg_op = 'UPDATE' then old.status else null end, new.status, actor_id, action_source);
  return new;
end;
$$;

create function public.validate_inventory_reservation()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  order_batch_id uuid;
begin
  select l.inventory_batch_id into order_batch_id
  from public.orders o join public.listings l on l.id = o.listing_id
  where o.id = new.order_id;
  if order_batch_id is distinct from new.inventory_batch_id then
    raise exception 'reservation batch must match the order listing batch';
  end if;
  return new;
end;
$$;

create trigger orders_validate before insert or update on public.orders
for each row execute function public.validate_order();
create trigger orders_validate_status before update of status on public.orders
for each row execute function public.validate_order_status_transition();
create trigger orders_record_initial_status after insert on public.orders
for each row
execute function public.record_order_status_history();
create trigger orders_record_changed_status after update of status on public.orders
for each row when (old.status is distinct from new.status)
execute function public.record_order_status_history();
create trigger inventory_reservations_validate before insert or update on public.inventory_reservations
for each row execute function public.validate_inventory_reservation();
create trigger orders_set_updated_at before update on public.orders
for each row execute function public.set_updated_at();
create trigger inventory_reservations_set_updated_at before update on public.inventory_reservations
for each row execute function public.set_updated_at();
