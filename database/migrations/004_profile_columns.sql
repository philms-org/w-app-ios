-- 004: reconcile profiles columns with WAPProfile/WAPRegistrationProfile
alter table profiles
  add column display_name text,
  add column phone text,
  add column gender text,
  add column date_of_birth date,
  add column avatar_url text,
  add column affiliation text[],
  add column role text[];

-- migrate any existing data (table is pre-launch/empty in practice, but safe either way)
update profiles set display_name = name where display_name is null and name is not null;
update profiles set avatar_url = photo_url where avatar_url is null and photo_url is not null;
alter table profiles alter column industry type text[] using case when industry is null then null else array[industry] end;

alter table profiles drop column name;
alter table profiles drop column photo_url;
alter table profiles alter column display_name set not null;
