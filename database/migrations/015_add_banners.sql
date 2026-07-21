-- 015_add_banners.sql
-- Restores the old get_home.php "banner" carousel (admin-managed promo images
-- shown at the top of the Home tab) as a real Supabase table. The legacy
-- backend's `banner` table (see wingme repo with database and admin panel/
-- database/wingme.sql) had image/location_Id/link columns managed via
-- /admin/banner_list; this is the same shape, adapted to the current schema
-- (location_id references the live locations table's uuid, not the old
-- integer id).

create table banners (
  id uuid primary key default uuid_generate_v4(),
  image_url text not null,
  location_id uuid references locations(id) on delete set null,
  link text,
  display_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz default now()
);

alter table banners enable row level security;

create policy banners_select on banners for select
  using (is_active);
