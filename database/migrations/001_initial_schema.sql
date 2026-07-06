-- WAP Initial Schema
-- Migration 001: All tables, RLS, and Realtime configuration

create extension if not exists "uuid-ossp";

-- 1. profiles
create table profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  name text not null,
  photo_url text,
  city text,
  industry text,
  created_at timestamptz default now()
);

alter table profiles enable row level security;

-- 2. locations (created before profile_field_definitions so FK can reference it)
create table locations (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  address text,
  lat double precision not null,
  lng double precision not null,
  geofence_radius_meters int default 100,
  owner_id uuid references profiles(id),
  is_event boolean default false,
  event_date timestamptz,
  banner_image text,
  created_at timestamptz default now()
);

alter table locations enable row level security;

-- 3. profile_field_definitions
create table profile_field_definitions (
  id uuid primary key default uuid_generate_v4(),
  label text not null,
  field_type text check (field_type in ('text', 'dropdown', 'number')) not null,
  is_global boolean default true,
  location_id uuid references locations(id) on delete cascade,
  display_order int default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

alter table profile_field_definitions enable row level security;

-- 4. profile_field_values
create table profile_field_values (
  user_id uuid references profiles(id) on delete cascade,
  field_definition_id uuid references profile_field_definitions(id) on delete cascade,
  value text,
  is_visible boolean default true,
  primary key (user_id, field_definition_id)
);

alter table profile_field_values enable row level security;

-- 5. profile_images
create table profile_images (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id) on delete cascade,
  storage_path text not null,
  is_banner boolean default false,
  is_avatar boolean default false,
  display_order int default 0,
  created_at timestamptz default now()
);

alter table profile_images enable row level security;

-- 6. location_checkins
create table location_checkins (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id) on delete cascade,
  location_id uuid references locations(id) on delete cascade,
  mode text check (mode in ('live', 'peeking')) not null,
  checked_in_at timestamptz default now(),
  checked_out_at timestamptz
);

alter table location_checkins enable row level security;

-- 7. friendships
create table friendships (
  user_id uuid references profiles(id) on delete cascade,
  friend_id uuid references profiles(id) on delete cascade,
  connected_at timestamptz default now(),
  source text check (source in ('qr_scan', 'peek_invite', 'message')),
  primary key (user_id, friend_id)
);

alter table friendships enable row level security;

-- 8. peek_invites
create table peek_invites (
  id uuid primary key default uuid_generate_v4(),
  sender_id uuid references profiles(id) on delete cascade,
  peeker_id uuid references profiles(id) on delete cascade,
  location_id uuid references locations(id) on delete cascade,
  sent_at timestamptz default now(),
  accepted_at timestamptz
);

alter table peek_invites enable row level security;

-- 9. feed_posts
create table feed_posts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id) on delete cascade,
  location_id uuid references locations(id) on delete cascade,
  content text not null,
  zone_tag text,
  created_at timestamptz default now()
);

alter table feed_posts enable row level security;

-- 10. feed_reactions
create table feed_reactions (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid references feed_posts(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  reaction_type text default 'heart',
  created_at timestamptz default now(),
  unique(post_id, user_id)
);

alter table feed_reactions enable row level security;

-- 11. contact_methods
create table contact_methods (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id) on delete cascade,
  slot_order int not null check (slot_order between 1 and 6),
  type text check (type in ('whatsapp','linkedin','facebook','instagram','phone','link')) not null,
  value text,
  is_enabled boolean default false,
  unique(user_id, slot_order)
);

alter table contact_methods enable row level security;

-- 12. connections
create table connections (
  id uuid primary key default uuid_generate_v4(),
  scanner_id uuid references profiles(id) on delete cascade,
  scannee_id uuid references profiles(id) on delete cascade,
  location_id uuid references locations(id),
  scanned_at timestamptz default now()
);

alter table connections enable row level security;

-- 13. contact_taps
create table contact_taps (
  id uuid primary key default uuid_generate_v4(),
  connection_id uuid references connections(id) on delete cascade,
  method_type text not null,
  tapped_at timestamptz default now()
);

alter table contact_taps enable row level security;

-- 14. rewards
create table rewards (
  id uuid primary key default uuid_generate_v4(),
  location_id uuid references locations(id) on delete cascade,
  name text not null,
  icon_type text default 'custom',
  deal_text text,
  instructions text,
  qr_path text,
  is_active boolean default true,
  display_order int default 0,
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

alter table rewards enable row level security;

-- 15. reward_claims
create table reward_claims (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id) on delete cascade,
  reward_id uuid references rewards(id) on delete cascade,
  claimed_at timestamptz default now(),
  verified_by uuid references profiles(id)
);

alter table reward_claims enable row level security;

-- 16. engagement_events
create table engagement_events (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id) on delete cascade,
  event_type text not null,
  points_earned int not null,
  created_at timestamptz default now()
);

alter table engagement_events enable row level security;

-- 17. feature_unlocks
create table feature_unlocks (
  id uuid primary key default uuid_generate_v4(),
  feature_name text unique not null,
  points_required int not null,
  description text
);

alter table feature_unlocks enable row level security;

-- 18. user_feature_access
create table user_feature_access (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id) on delete cascade,
  feature_name text not null,
  unlocked_at timestamptz default now(),
  granted_by uuid references profiles(id),
  unique(user_id, feature_name)
);

alter table user_feature_access enable row level security;

-- 19. verification_tags
create table verification_tags (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id) on delete cascade,
  location_id uuid references locations(id) on delete cascade,
  tag text not null,
  assigned_by uuid references profiles(id),
  assigned_at timestamptz default now()
);

alter table verification_tags enable row level security;

-- Enable Realtime on key tables
alter publication supabase_realtime add table location_checkins;
alter publication supabase_realtime add table feed_posts;
alter publication supabase_realtime add table peek_invites;
