insert into public.commodities (id, name, category, default_unit, shelf_life_days)
values
  ('00000000-0000-4000-8000-000000000001', 'Tomat', 'Sayuran', 'kg', null),
  ('00000000-0000-4000-8000-000000000002', 'Kentang', 'Umbi', 'kg', null),
  ('00000000-0000-4000-8000-000000000003', 'Cabai Merah', 'Sayuran', 'kg', null),
  ('00000000-0000-4000-8000-000000000004', 'Bawang Merah', 'Umbi', 'kg', null),
  ('00000000-0000-4000-8000-000000000005', 'Kacang Panjang', 'Sayuran', 'kg', 3)
on conflict (id) do update set
  name = excluded.name,
  category = excluded.category,
  default_unit = excluded.default_unit,
  shelf_life_days = excluded.shelf_life_days,
  is_active = true;
