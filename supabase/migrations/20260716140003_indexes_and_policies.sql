create index organizations_owner_user_id_idx on public.organizations(owner_user_id);
create index user_channels_user_id_idx on public.user_channels(user_id);
create index inventory_batches_organization_id_idx on public.inventory_batches(organization_id);
create index inventory_batches_commodity_id_idx on public.inventory_batches(commodity_id);
create index inventory_batches_status_available_at_idx on public.inventory_batches(status, available_at);
create index inventory_reservations_batch_status_idx on public.inventory_reservations(inventory_batch_id, status);
create index inventory_reservations_order_id_idx on public.inventory_reservations(order_id);
create index inventory_movements_batch_created_at_idx on public.inventory_movements(inventory_batch_id, created_at);
create index listings_batch_id_idx on public.listings(inventory_batch_id);
create index listings_status_published_at_idx on public.listings(status, published_at);
create index listings_type_status_expires_at_idx on public.listings(listing_type, status, expires_at);
create index demands_buyer_status_idx on public.demands(buyer_organization_id, status);
create index demands_commodity_status_needed_at_idx on public.demands(commodity_id, status, needed_at);
create index matches_demand_score_idx on public.matches(demand_id, score desc);
create index matches_listing_status_idx on public.matches(listing_id, status);
create index orders_buyer_status_idx on public.orders(buyer_organization_id, status);
create index orders_seller_status_idx on public.orders(seller_organization_id, status);
create index orders_created_at_idx on public.orders(created_at);
create index order_status_history_order_created_at_idx on public.order_status_history(order_id, created_at);
create index conversation_sessions_user_status_idx on public.conversation_sessions(user_id, status);
create index incoming_messages_status_received_at_idx on public.incoming_messages(processing_status, received_at);
create index outgoing_messages_status_scheduled_at_idx on public.outgoing_messages(status, scheduled_at);
create index audit_logs_entity_idx on public.audit_logs(entity_type, entity_id);
create index audit_logs_actor_created_at_idx on public.audit_logs(actor_user_id, created_at);
create index knowledge_chunks_document_idx on public.knowledge_chunks(document_id, chunk_index);
create index jobs_claim_idx on public.jobs(priority desc, available_at)
where status in ('PENDING', 'FAILED');
create index jobs_lock_expires_at_idx on public.jobs(lock_expires_at)
where status = 'PROCESSING';

create function public.owns_organization(p_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.users u
    where u.id = auth.uid()
      and (
        u.role = 'ADMIN'
        or exists (
          select 1 from public.organizations o
          where o.id = p_organization_id and o.owner_user_id = u.id
        )
      )
  );
$$;

create function public.can_view_match(p_demand_id uuid, p_listing_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.demands d
    join public.listings l on l.id = p_listing_id
    join public.inventory_batches b on b.id = l.inventory_batch_id
    join public.users u on u.id = auth.uid()
    where d.id = p_demand_id
      and (
        u.role = 'ADMIN'
        or d.buyer_organization_id in (
          select o.id from public.organizations o where o.owner_user_id = u.id
        )
        or b.organization_id in (
          select o.id from public.organizations o where o.owner_user_id = u.id
        )
      )
  );
$$;

create function public.can_view_order(p_order_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.orders o
    join public.users u on u.id = auth.uid()
    where o.id = p_order_id
      and (
        u.role = 'ADMIN'
        or o.buyer_organization_id in (
          select org.id from public.organizations org where org.owner_user_id = u.id
        )
        or o.seller_organization_id in (
          select org.id from public.organizations org where org.owner_user_id = u.id
        )
      )
  );
$$;

revoke all on function public.owns_organization(uuid) from public;
revoke all on function public.can_view_match(uuid, uuid) from public;
revoke all on function public.can_view_order(uuid) from public;
grant execute on function public.owns_organization(uuid) to authenticated;
grant execute on function public.can_view_match(uuid, uuid) to authenticated;
grant execute on function public.can_view_order(uuid) to authenticated;

alter table public.users enable row level security;
alter table public.organizations enable row level security;
alter table public.user_channels enable row level security;
alter table public.commodities enable row level security;
alter table public.inventory_batches enable row level security;
alter table public.inventory_reservations enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.listings enable row level security;
alter table public.listing_media enable row level security;
alter table public.demands enable row level security;
alter table public.matches enable row level security;
alter table public.orders enable row level security;
alter table public.order_status_history enable row level security;
alter table public.conversation_sessions enable row level security;
alter table public.incoming_messages enable row level security;
alter table public.outgoing_messages enable row level security;
alter table public.bot_actions enable row level security;
alter table public.audit_logs enable row level security;
alter table public.jobs enable row level security;
alter table public.knowledge_documents enable row level security;
alter table public.knowledge_chunks enable row level security;

create policy matches_owner_read on public.matches
for select to authenticated
using (public.can_view_match(demand_id, listing_id));

create policy orders_owner_read on public.orders
for select to authenticated
using (
  public.owns_organization(buyer_organization_id)
  or public.owns_organization(seller_organization_id)
);

create policy order_status_history_owner_read on public.order_status_history
for select to authenticated
using (public.can_view_order(order_id));

revoke all on table
  public.users, public.organizations, public.user_channels, public.commodities,
  public.inventory_batches, public.inventory_reservations, public.inventory_movements,
  public.listings, public.listing_media, public.demands, public.matches, public.orders,
  public.order_status_history, public.conversation_sessions, public.incoming_messages,
  public.outgoing_messages, public.bot_actions, public.audit_logs, public.jobs,
  public.knowledge_documents, public.knowledge_chunks
from anon, authenticated;

grant select on table public.matches, public.orders, public.order_status_history to authenticated;

do $$
declare
  table_name text;
begin
  foreach table_name in array array['matches', 'orders', 'order_status_history'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = table_name
    ) then
      execute format('alter publication supabase_realtime add table public.%I', table_name);
    end if;
  end loop;
end;
$$;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'listing-media',
  'listing-media',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
