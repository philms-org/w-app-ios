-- 016_venue_photos.sql
-- Documents a table (`venue_photos`) that already exists in production but had
-- no migration file anywhere in this repo or w-app-web — pure schema drift,
-- discovered while mirroring prod into a new w-app-qa Supabase project.
-- Definition below was reverse-engineered from prod via information_schema /
-- pg_constraint / pg_policies and applied to w-app-qa unchanged; this file
-- exists so future environments (and this one, if ever rebuilt) don't drift
-- again.

create table venue_photos (
  id uuid primary key default uuid_generate_v4(),
  venue_id uuid not null references locations(id) on delete cascade,
  image_url text not null,
  position integer not null default 0,
  created_at timestamptz default now()
);

create index venue_photos_venue_id_idx on venue_photos using btree (venue_id, position);

alter table venue_photos enable row level security;

create policy "venue_photos_select" on venue_photos for select to authenticated using (true);
