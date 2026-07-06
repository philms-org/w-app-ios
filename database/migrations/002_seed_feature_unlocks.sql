-- WAP Seed Data
-- Migration 002: feature_unlocks and global profile_field_definitions

insert into feature_unlocks (feature_name, points_required, description) values
  ('contact_slot_3_4', 100,  'Unlock 3rd and 4th contact method slots'),
  ('map_view',         250,  'Unlock map view'),
  ('contact_slot_5_6', 500,  'Unlock 5th and 6th contact method slots'),
  ('anonymous_peek',   1000, 'Peek anonymously without appearing on live feed'),
  ('extended_history', 2000, 'Extended history and custom field access')
on conflict (feature_name) do nothing;

insert into profile_field_definitions (label, field_type, is_global, location_id, display_order) values
  ('Age',                 'number', true, null, 1),
  ('Fave Drink',          'text',   true, null, 2),
  ('Nationality',         'text',   true, null, 3),
  ('Bio',                 'text',   true, null, 4),
  ('On Friday Night I...','text',   true, null, 5)
on conflict do nothing;
