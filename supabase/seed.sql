insert into public.commodities (id, name, category, default_unit)
values
  ('00000000-0000-4000-8000-000000000001', 'Tomat', 'Sayuran', 'kg'),
  ('00000000-0000-4000-8000-000000000002', 'Kentang', 'Umbi', 'kg'),
  ('00000000-0000-4000-8000-000000000003', 'Cabai Merah', 'Sayuran', 'kg'),
  ('00000000-0000-4000-8000-000000000004', 'Bawang Merah', 'Umbi', 'kg')
on conflict (id) do update set
  name = excluded.name,
  category = excluded.category,
  default_unit = excluded.default_unit,
  is_active = true;
