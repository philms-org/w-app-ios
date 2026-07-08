# Event/Venue Attendee History — Design Spec

## Context

Users can currently see who's at a venue *right now* (live presence, via `location_checkins`/the WHO'S HERE tab). There's no way to see who has *ever* attended a venue or event across all past visits — a different, all-time roster. This spec adds that: a per-venue historical attendee list, with a per-venue opt-out for users who don't want to appear in it, and an admin-controlled feature-flag system that gates both (global default, with city/location/individual overrides).

While designing this, cross-referencing `WAPData.swift`/`WAPModels.swift` against the real Supabase schema (`database/migrations/001_initial_schema.sql`) surfaced a pre-existing, unrelated problem: the Swift data layer targets tables and columns that don't exist in the real schema (`venues` instead of `locations`, `venue_presence` instead of `location_checkins`, `social_links` instead of `contact_methods`, and a `profiles` shape with columns like `display_name`/`phone`/`gender`/`date_of_birth` that the real `profiles` table doesn't have). This means venues, presence, contacts, and registration are all currently broken against the real backend, independent of this feature. Per your direction, that gets fixed first, as its own small prerequisite — documented here for context, planned as a straightforward reconciliation rather than a full brainstormed feature.

## Prerequisite: Schema Reconciliation

Not new functionality — fixing existing code to match the schema it was always supposed to target.

1. **`profiles` table** — add missing columns via migration `004_profile_columns.sql`: `display_name text`, `phone text`, `gender text`, `date_of_birth date`, `avatar_url text`, `affiliation text[]`, `industry text[]` (replacing the existing plain `industry text` — confirm no data loss, table is pre-launch/empty), `role text[]`. Keep existing `name`, `photo_url`, `city`, `created_at` — `WAPProfile` should map to whichever of `name`/`display_name` and `photo_url`/`avatar_url` end up canonical; recommend deprecating the older column name in favor of the one the Swift layer already uses (`display_name`, `avatar_url`), migrating `name`→`display_name` and `photo_url`→`avatar_url` data if any exists, then dropping the old columns.
2. **`WAPData.swift`** — rename `.from("venues")` → `.from("locations")`, update `WAPVenue` codable keys if any column names differ from `locations`' actual columns (`name`, `address`, `lat`, `lng`, `geofence_radius_meters`, `banner_image`, `is_event`, `event_date`) — `WAPVenue` currently has `latitude`/`longitude`/`radius`/`bannerURL`/`welcomeText`, none of which match; reconcile field-by-field.
3. **Presence** — `venue_presence` doesn't exist; `location_checkins` is shaped differently (`mode` enum `'live'|'peeking'`, `checked_in_at`, `checked_out_at`, no simple upsert-a-presence-row semantics). Rewrite `WAPData.checkIn`/`checkOut`/`fetchPresence` against `location_checkins`: check-in = insert a row with `mode: 'live'`, `checked_out_at: null`; check-out = set `checked_out_at = now()` on the open row; "who's here" = rows where `checked_out_at is null`.
4. **Contacts** — `social_links` doesn't exist; `contact_methods` has a fixed 6-slot shape (`slot_order 1-6`, `type` enum, `is_enabled`). Reshape `WAPSocialLink` and `WAPData.fetchLinks`/`upsertLink` to match, or redesign the QR/Contacts screen's data layer around the slot model directly.
5. **RLS policies** — `003_rls_policies.sql` (already run) has policies on `contacts_shared` and `user_rewards`, neither of which exist. Add migration `005_rls_policy_fixes.sql` with corrected policies on `contact_methods` and `rewards`/`reward_claims`, matching the same ownership rules `003` intended.

This prerequisite is scoped as a straight reconciliation (make code match schema, or schema match code, table by table) — no new design decisions, so it goes directly into the implementation plan rather than through another brainstorming pass.

## Feature: Attendee History

### Data Model

```sql
-- Global default per gated feature
create table feature_flags (
  feature_name text primary key,       -- 'attendee_history_view' | 'attendee_history_hide_self'
  default_enabled boolean not null default false,
  description text
);

-- Scoped overrides: city, location, or individual user
create table feature_flag_overrides (
  id uuid primary key default uuid_generate_v4(),
  feature_name text references feature_flags(feature_name) not null,
  scope_type text check (scope_type in ('city', 'location', 'user')) not null,
  scope_value text not null,   -- city name, location_id, or user_id (as text)
  enabled boolean not null,
  set_by uuid references profiles(id),
  set_at timestamptz default now(),
  unique(feature_name, scope_type, scope_value)
);

-- Add city to locations (currently only has address/lat/lng)
alter table locations add column city text;

-- Per-user, per-venue opt-out from appearing in that venue's attendee history
create table attendee_history_opt_outs (
  user_id uuid references profiles(id) on delete cascade,
  location_id uuid references locations(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, location_id)
);

insert into feature_flags (feature_name, default_enabled, description) values
  ('attendee_history_view', false, 'View a venue''s all-time attendee roster'),
  ('attendee_history_hide_self', true, 'Allow a user to opt out of a venue''s attendee roster');
```

RLS: `feature_flags`/`feature_flag_overrides` need `SELECT` open to `authenticated` (resolution happens client-side in `WAPData`, so the app needs to read them) but no `INSERT`/`UPDATE`/`DELETE` policy for regular users — writes stay admin-only via the Supabase Table Editor (service-role bypasses RLS). `attendee_history_opt_outs`: `SELECT` open to `authenticated` (needed to exclude opted-out users when building a roster; membership alone isn't sensitive), `INSERT`/`DELETE` restricted to `user_id = auth.uid()`.

### Resolution Logic

One function, used for both `attendee_history_view` and `attendee_history_hide_self`, given a feature name, the viewing/acting user, and a target location:

1. `feature_flag_overrides` row with `scope_type = 'location'`, `scope_value = location_id`? → use its `enabled` value. (Venue's explicit choice always wins — locations are paying clients with ultimate governance over their own page.)
2. Else, row with `scope_type = 'user'`, `scope_value = user_id`? → use it.
3. Else, row with `scope_type = 'city'`, `scope_value = locations.city` (for this location)? → use it.
4. Else, `feature_flags.default_enabled` for that feature name.

### API Layer (`WAPData.swift` additions)

- `resolveFeatureFlag(featureName: String, userId: String, location: WAPVenue) async throws -> Bool`
- `fetchAttendeeHistory(locationId: String) async throws -> [WAPProfile]` — distinct users from `location_checkins` for that location, excluding `attendee_history_opt_outs` rows. Caller must have already confirmed `resolveFeatureFlag("attendee_history_view", ...)`.
- `setAttendeeHistoryOptOut(locationId: String, hidden: Bool) async throws` — insert/delete the opt-out row. Caller must have already confirmed `resolveFeatureFlag("attendee_history_hide_self", ...)`.

### UI

- **Venue page:** an "Attendees" entry point next to WHO'S HERE, styled like the existing presence-row cells. Hidden entirely (not shown disabled) when `attendee_history_view` resolves false for that venue/user.
- **Roster row (own row only):** a "Hide me from this venue's history" toggle, shown only when `attendee_history_hide_self` resolves true for that venue/user.
- **Admin management:** explicitly out of scope for v1 — no native admin screens exist anywhere in the app yet, and building one just for two tables isn't worth it. Admin manages `feature_flags` and `feature_flag_overrides` directly via the Supabase Table Editor, which already provides full CRUD.

## Non-Goals

- Not reusing the existing points-based `feature_unlocks`/`user_feature_access` system — that models users *earning* access via points; this feature is admin-*assigned* access at four scopes, a different mechanism.
- No native in-app admin UI for managing the flags (Supabase Table Editor instead).
- The "who was here at the same time as you" live-presence feature is unchanged — this spec only adds the all-time historical view.
- Hide-self is per-venue (per earlier decision), not a single global toggle.
