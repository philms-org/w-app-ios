-- 007: reward tiering via feature_unlocks reference
alter table rewards add column if not exists feature_name text references feature_unlocks(feature_name);
