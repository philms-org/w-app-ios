-- 014_add_missing_profile_fields.sql
-- WAPModels.swift's WAPProfile struct (iOS) has declared these fields since
-- before this migration existed, and the web port (lib/types.ts, built this
-- week) assumes the same schema — but no prior migration (checked 001-013)
-- ever actually added them to the profiles table. Confirmed live via direct
-- REST calls: email/fave_drink/friday_night/profession/city_visible/
-- fave_drink_visible/friday_night_visible/profession_visible/is_verified all
-- return PostgREST 400 "column does not exist" today. Both the register
-- screen (email) and profile-setup screen (fave_drink/friday_night/
-- profession) on iOS and web already collect this data and upsert it — this
-- migration makes that already-built code actually work.

alter table profiles
  add column if not exists email text,
  add column if not exists fave_drink text,
  add column if not exists friday_night text,
  add column if not exists profession text,
  add column if not exists city_visible boolean default true,
  add column if not exists fave_drink_visible boolean default true,
  add column if not exists friday_night_visible boolean default true,
  add column if not exists profession_visible boolean default true,
  add column if not exists is_verified boolean default false;
