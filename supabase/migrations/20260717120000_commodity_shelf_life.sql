alter table public.commodities
add column shelf_life_days integer check (shelf_life_days > 0);

comment on column public.commodities.shelf_life_days is
'Default umur simpan dalam hari sejak inventory_batches.harvested_at; null berarti belum ditentukan.';
