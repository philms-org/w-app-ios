-- 004: reconcile profiles columns with WAPProfile/WAPRegistrationProfile
alter table profiles
  add column if not exists display_name text,
  add column if not exists phone text,
  add column if not exists gender text,
  add column if not exists date_of_birth date,
  add column if not exists avatar_url text,
  add column if not exists affiliation text[],
  add column if not exists role text[];

-- migrate any existing data (table is pre-launch/empty in practice, but safe either way)
update profiles set display_name = name where display_name is null and name is not null;
update profiles set avatar_url = photo_url where avatar_url is null and photo_url is not null;
alter table profiles alter column industry type text[] using case when industry is null then null else array[industry] end;

alter table profiles drop column if exists name;
alter table profiles drop column if exists photo_url;
alter table profiles alter column display_name set not null;
