alter table public.inventory_batches
add column photo_storage_path text check (
  photo_storage_path is null or length(trim(photo_storage_path)) > 0
);

comment on column public.inventory_batches.photo_storage_path is
'Path privat foto batch pada object storage; akses client menggunakan signed URL dari backend.';
