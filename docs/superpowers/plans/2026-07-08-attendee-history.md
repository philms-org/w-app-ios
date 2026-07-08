# Attendee History Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Apply the `ponytail` skill's YAGNI discipline throughout — no speculative abstraction, no config for hypothetical future scopes, reuse existing helpers (`imageFromServerURL`, `WPillButton`, `Colors`) instead of rebuilding them. For Swift-specific review passes beyond the standard task reviewer, the `ecc:swift-reviewer` agent and `ecc:database-reviewer` agent (for the SQL migrations) are available — use them as the task reviewer for Tasks 1, 5, 6 (SQL) and 2–4, 7–10 (Swift) respectively if deeper domain review is wanted beyond the standard reviewer.

**Goal:** Fix the pre-existing mismatch between `WAPData.swift`/`WAPModels.swift` and the real Supabase schema (Track A), then build the all-time venue attendee history feature with a 4-level admin flag system (Track B), per `docs/superpowers/specs/2026-07-08-attendee-history-design.md`.

**Architecture:** Track A is a straight reconciliation — no new design decisions, just making Swift code match the schema in `database/migrations/001_initial_schema.sql`. Track B adds three new tables (`feature_flags`, `feature_flag_overrides`, `attendee_history_opt_outs`) plus a `locations.city` column, a pure-function flag resolver (unit tested), `WAPData` methods built on the corrected Track A foundation, and a new standalone `AttendeeHistoryVC` wired into the existing venue screen (`NewMyLocationVC`) via one entry-point button.

**Tech Stack:** Swift 5, UIKit, Supabase Swift SDK 2.50.0, XCTest, Supabase Postgres/RLS.

## Global Constraints

- Auth token in Keychain only (`KeychainHelper.Keys.authToken`), never UserDefaults.
- SUPABASE_URL/SUPABASE_ANON_KEY stay in Xcode Edit Scheme env vars, never committed.
- Module name for `@testable import` is `The_W_App` (matches `WAPSupabaseTests.swift`; note `KeychainHelperTests.swift` and `WAPAuthTests.swift` currently import `TheWApp` without the underscore — a pre-existing bug outside this plan's scope, don't fix it here, don't copy it into new test files).
- Open `The W App.xcworkspace`, never `.xcodeproj`.
- Verify each Swift task by running a full build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build` from `/Users/sr/wingme-copy`. Network-dependent Supabase calls (fetch/insert/upsert against live tables) have no mocking infrastructure in this codebase yet — treat a clean build plus the existing pattern (as used for `WAPSupabaseTests.swift`) as the automated check for those; only pure, network-free logic (the flag resolver in Task 7) gets a real XCTest.
- New/changed SQL migrations are numbered sequentially after the existing `003_rls_policies.sql`: `004`, `005`, `006`. Each is idempotent-safe (`drop policy if exists` before `create policy`) since it's unknown exactly how far `003` got before failing (see Task 5).

---

## Track A: Schema Reconciliation

### Task 1: Add missing `profiles` columns

**Files:**
- Create: `database/migrations/004_profile_columns.sql`

**Interfaces:**
- Produces: `profiles` table with columns `display_name`, `phone`, `gender`, `date_of_birth`, `avatar_url`, `affiliation text[]`, `role text[]`, replacing the old `name`/`photo_url`/`industry text` shape — matches what `WAPProfile`/`WAPRegistrationProfile` (in `Wing Me/Classes/WAPModels.swift` and `Wing Me/Classes/WAPSupabase.swift`) already assume.

- [ ] **Step 1: Write the migration**

```sql
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
```

- [ ] **Step 2: Run it in the Supabase SQL Editor**

Paste the contents of `004_profile_columns.sql` into the Supabase project's SQL Editor and run it. Expected: no errors, `profiles` table in the Table Editor now shows `display_name`, `phone`, `gender`, `date_of_birth`, `avatar_url`, `affiliation`, `industry` (now `text[]`), `role`, `city`, `created_at` — `name`/`photo_url` gone.

- [ ] **Step 3: Commit**

```bash
cd /Users/sr/wingme-copy
git add database/migrations/004_profile_columns.sql
git commit -m "chore: reconcile profiles table columns with WAPProfile model"
```

---

### Task 2: Fix `WAPVenue` model and venue queries

**Files:**
- Modify: `Wing Me/Classes/WAPModels.swift` (the `WAPVenue` struct)
- Modify: `Wing Me/Classes/WAPData.swift` (`fetchVenues`, `fetchVenue`)
- Test: `The W AppTests/WAPModelsTests.swift`

**Interfaces:**
- Consumes: real `locations` columns from `database/migrations/001_initial_schema.sql`: `id`, `name`, `address`, `lat`, `lng`, `geofence_radius_meters`, `owner_id`, `is_event`, `event_date`, `banner_image`, `created_at`. `city` doesn't exist on `locations` yet — added in Task 6 — so `WAPVenue.city` stays optional and decodes as `nil` until then.
- Produces: `WAPVenue` with fields `id, name, address, city, lat, lng, geofenceRadiusMeters, isEvent, eventDate, bannerImage` — this is the shape Task 6–10 build on.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import The_W_App

final class WAPModelsTests: XCTestCase {
    func testWAPVenueDecodesRealLocationsColumns() throws {
        let json = """
        {"id":"loc-1","name":"Hallowell House","address":"123 Main St","city":"Austin",
         "lat":30.27,"lng":-97.74,"geofence_radius_meters":100,
         "is_event":false,"event_date":null,"banner_image":"https://x/banner.jpg"}
        """.data(using: .utf8)!
        let venue = try JSONDecoder().decode(WAPVenue.self, from: json)
        XCTAssertEqual(venue.name, "Hallowell House")
        XCTAssertEqual(venue.geofenceRadiusMeters, 100)
        XCTAssertEqual(venue.bannerImage, "https://x/banner.jpg")
        XCTAssertEqual(venue.isEvent, false)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" test -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:TheWAppTests/WAPModelsTests`
Expected: FAIL — `WAPVenue` has no member `geofenceRadiusMeters`/`bannerImage`/`isEvent` yet (current struct has `latitude`/`longitude`/`radius`/`bannerURL`/`welcomeText`, which don't match).

- [ ] **Step 3: Fix `WAPVenue`**

In `Wing Me/Classes/WAPModels.swift`, replace the `WAPVenue` struct:

```swift
struct WAPVenue: Codable, Identifiable {
    let id: String
    var name: String
    var address: String?
    var city: String?
    var lat: Double?
    var lng: Double?
    var geofenceRadiusMeters: Int?
    var isEvent: Bool?
    var eventDate: String?
    var bannerImage: String?

    enum CodingKeys: String, CodingKey {
        case id, name, address, city, lat, lng
        case geofenceRadiusMeters = "geofence_radius_meters"
        case isEvent = "is_event"
        case eventDate = "event_date"
        case bannerImage = "banner_image"
    }
}
```

- [ ] **Step 4: Fix the venue queries in `WAPData.swift`**

Replace:

```swift
    func fetchVenues() async throws -> [WAPVenue] {
        try await client
            .from("venues")
            .select()
            .order("name")
            .execute()
            .value
    }

    func fetchVenue(id: String) async throws -> WAPVenue {
        try await client
            .from("venues")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }
```

with:

```swift
    func fetchVenues() async throws -> [WAPVenue] {
        try await client
            .from("locations")
            .select()
            .order("name")
            .execute()
            .value
    }

    func fetchVenue(id: String) async throws -> WAPVenue {
        try await client
            .from("locations")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }
```

- [ ] **Step 5: Run test to verify it passes, then build**

Run the same `-only-testing:TheWAppTests/WAPModelsTests` command. Expected: PASS.
Then: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`. Expected: BUILD SUCCEEDED (this will also surface any other file still referencing the old `WAPVenue` field names — fix any that appear).

- [ ] **Step 6: Commit**

```bash
git add "Wing Me/Classes/WAPModels.swift" "Wing Me/Classes/WAPData.swift" "The W AppTests/WAPModelsTests.swift"
git commit -m "fix: WAPVenue and venue queries target real locations table/columns"
```

---

### Task 3: Fix presence (`location_checkins`)

**Files:**
- Modify: `Wing Me/Classes/WAPModels.swift` (the `WAPPresence` struct)
- Modify: `Wing Me/Classes/WAPData.swift` (`fetchPresence`, `checkIn`, `checkOut`)

**Interfaces:**
- Consumes: real `location_checkins` columns: `id`, `user_id`, `location_id`, `mode` (`'live'|'peeking'`), `checked_in_at`, `checked_out_at`.
- Produces: `WAPPresence(id, locationId, userId, mode, checkedInAt, checkedOutAt, profile)`; `WAPData.fetchPresence(locationId:)`, `checkIn(locationId:)`, `checkOut(locationId:)` — Task 8 (attendee roster) reads the same `location_checkins` table.

- [ ] **Step 1: Fix `WAPPresence`**

In `Wing Me/Classes/WAPModels.swift`, replace:

```swift
struct WAPPresence: Codable, Identifiable {
    let id: String
    let venueId: String
    let userId: String
    var checkedInAt: String?
    var profile: WAPProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case venueId     = "venue_id"
        case userId      = "user_id"
        case checkedInAt = "checked_in_at"
        case profile     = "profiles"
    }
}
```

with:

```swift
struct WAPPresence: Codable, Identifiable {
    let id: String
    let locationId: String
    let userId: String
    var mode: String
    var checkedInAt: String?
    var checkedOutAt: String?
    var profile: WAPProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case locationId  = "location_id"
        case userId      = "user_id"
        case mode
        case checkedInAt  = "checked_in_at"
        case checkedOutAt = "checked_out_at"
        case profile      = "profiles"
    }
}
```

- [ ] **Step 2: Fix the presence methods in `WAPData.swift`**

Replace:

```swift
    func fetchPresence(venueId: String) async throws -> [WAPPresence] {
        try await client
            .from("venue_presence")
            .select("*, profiles(*)")
            .eq("venue_id", value: venueId)
            .execute()
            .value
    }

    func checkIn(venueId: String) async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        struct Presence: Encodable {
            let venue_id: String
            let user_id: String
        }
        try await client
            .from("venue_presence")
            .upsert(Presence(venue_id: venueId, user_id: uid))
            .execute()
    }

    func checkOut(venueId: String) async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        try await client
            .from("venue_presence")
            .delete()
            .eq("venue_id", value: venueId)
            .eq("user_id", value: uid)
            .execute()
    }
```

with:

```swift
    func fetchPresence(locationId: String) async throws -> [WAPPresence] {
        try await client
            .from("location_checkins")
            .select("*, profiles(*)")
            .eq("location_id", value: locationId)
            .is("checked_out_at", value: nil)
            .execute()
            .value
    }

    func checkIn(locationId: String) async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        struct CheckIn: Encodable {
            let user_id: String
            let location_id: String
            let mode: String
        }
        try await client
            .from("location_checkins")
            .insert(CheckIn(user_id: uid, location_id: locationId, mode: "live"))
            .execute()
    }

    func checkOut(locationId: String) async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        struct CheckOut: Encodable { let checked_out_at: String }
        let now = ISO8601DateFormatter().string(from: Date())
        try await client
            .from("location_checkins")
            .update(CheckOut(checked_out_at: now))
            .eq("user_id", value: uid)
            .eq("location_id", value: locationId)
            .is("checked_out_at", value: nil)
            .execute()
    }
```

- [ ] **Step 3: Update callers**

Run: `grep -rn "fetchPresence(venueId\|checkIn(venueId\|checkOut(venueId" "Wing Me" --include="*.swift"` from `/Users/sr/wingme-copy`. Update any call sites found to use `locationId:` instead of `venueId:` (parameter name changed, not just type — Swift call sites use argument labels).

- [ ] **Step 4: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add "Wing Me/Classes/WAPModels.swift" "Wing Me/Classes/WAPData.swift"
git commit -m "fix: presence targets real location_checkins table/shape instead of venue_presence"
```

---

### Task 4: Fix contacts (`contact_methods`)

**Files:**
- Modify: `Wing Me/Classes/WAPModels.swift` (rename `WAPSocialLink` → `WAPContactMethod`)
- Modify: `Wing Me/Classes/WAPData.swift` (`fetchLinks`/`upsertLink` → `fetchContactMethods`/`upsertContactMethod`)

**Interfaces:**
- Consumes: real `contact_methods` columns: `id`, `user_id`, `slot_order` (1–6), `type` (`whatsapp|linkedin|facebook|instagram|phone|link`), `value`, `is_enabled`.
- Produces: `WAPContactMethod(id, userId, slotOrder, type, value, isEnabled)`.

- [ ] **Step 1: Check for existing usages before renaming**

Run: `grep -rln "WAPSocialLink\|fetchLinks\|upsertLink" "Wing Me" --include="*.swift"` from `/Users/sr/wingme-copy`. Expected today: only `WAPModels.swift` and `WAPData.swift` (no UI built against this yet, per the QR Code screens still being on the old PHP path) — if any other file appears, update it in Step 3 alongside the rename.

- [ ] **Step 2: Rename and reshape the model**

In `Wing Me/Classes/WAPModels.swift`, replace:

```swift
struct WAPSocialLink: Codable, Identifiable {
    let id: String
    let userId: String
    var platform: String
    var url: String
    var isVisible: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case platform
        case url
        case isVisible = "is_visible"
    }
}
```

with:

```swift
struct WAPContactMethod: Codable, Identifiable {
    let id: String
    let userId: String
    var slotOrder: Int
    var type: String
    var value: String?
    var isEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case slotOrder = "slot_order"
        case type
        case value
        case isEnabled = "is_enabled"
    }
}
```

- [ ] **Step 3: Fix the queries in `WAPData.swift`**

Replace:

```swift
    func fetchLinks(userId: String) async throws -> [WAPSocialLink] {
        try await client
            .from("social_links")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
    }

    func upsertLink(_ link: WAPSocialLink) async throws {
        try await client
            .from("social_links")
            .upsert(link)
            .execute()
    }
```

with:

```swift
    func fetchContactMethods(userId: String) async throws -> [WAPContactMethod] {
        try await client
            .from("contact_methods")
            .select()
            .eq("user_id", value: userId)
            .order("slot_order")
            .execute()
            .value
    }

    func upsertContactMethod(_ method: WAPContactMethod) async throws {
        try await client
            .from("contact_methods")
            .upsert(method)
            .execute()
    }
```

- [ ] **Step 4: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add "Wing Me/Classes/WAPModels.swift" "Wing Me/Classes/WAPData.swift"
git commit -m "fix: rename WAPSocialLink to WAPContactMethod, target real contact_methods table/shape"
```

---

### Task 5: Fix RLS policies (migration 005)

**Files:**
- Create: `database/migrations/005_rls_policy_fixes.sql`

**Interfaces:**
- Produces: correct RLS policies on `contact_methods` and `rewards`/`reward_claims` (replacing `003_rls_policies.sql`'s references to the nonexistent `contacts_shared`/`user_rewards`). Also re-asserts policies on `peek_invites`, `locations`, `feature_unlocks`, `profile_field_definitions` in case `003` stopped before reaching them (Postgres has no `CREATE POLICY IF NOT EXISTS`; `003`'s `contacts_shared` statement would have hard-failed, and depending on how it was run, everything after that point in the script may never have executed).

- [ ] **Step 1: Write the migration**

```sql
-- 005: fix RLS policies that referenced nonexistent tables in 003
-- (003 referenced contacts_shared and user_rewards, which don't exist —
--  the real tables are contact_methods and rewards/reward_claims).
-- Every statement below is drop-then-create so this is safe to run
-- regardless of exactly where 003 stopped.

drop policy if exists "contacts_select" on contact_methods;
drop policy if exists "contacts_insert" on contact_methods;
create policy "contacts_select" on contact_methods for select to authenticated using (true);
create policy "contacts_insert" on contact_methods for insert to authenticated with check (user_id = auth.uid());
create policy "contacts_update" on contact_methods for update to authenticated using (user_id = auth.uid());

drop policy if exists "rewards_select" on rewards;
create policy "rewards_select" on rewards for select to authenticated using (true);

drop policy if exists "reward_claims_select" on reward_claims;
drop policy if exists "reward_claims_insert" on reward_claims;
create policy "reward_claims_select" on reward_claims for select to authenticated using (user_id = auth.uid());
create policy "reward_claims_insert" on reward_claims for insert to authenticated with check (user_id = auth.uid());

-- re-assert in case 003 stopped before these
drop policy if exists "peeks_select" on peek_invites;
drop policy if exists "peeks_insert" on peek_invites;
drop policy if exists "peeks_update" on peek_invites;
create policy "peeks_select" on peek_invites for select to authenticated using (sender_id = auth.uid() or peeker_id = auth.uid());
create policy "peeks_insert" on peek_invites for insert to authenticated with check (sender_id = auth.uid());
create policy "peeks_update" on peek_invites for update to authenticated using (peeker_id = auth.uid());

drop policy if exists "locations_select" on locations;
create policy "locations_select" on locations for select to authenticated using (true);

drop policy if exists "features_select" on feature_unlocks;
create policy "features_select" on feature_unlocks for select to authenticated using (true);

drop policy if exists "field_defs_select" on profile_field_definitions;
create policy "field_defs_select" on profile_field_definitions for select to authenticated using (true);
```

- [ ] **Step 2: Run it in the Supabase SQL Editor**

Paste and run. Expected: no errors. Confirm in Dashboard → Authentication → Policies that `contact_methods`, `rewards`, `reward_claims`, `peek_invites`, `locations`, `feature_unlocks`, `profile_field_definitions` all show policies.

- [ ] **Step 3: Commit**

```bash
git add database/migrations/005_rls_policy_fixes.sql
git commit -m "fix: RLS policies on real table names (contact_methods, rewards/reward_claims)"
```

---

## Track B: Attendee History Feature

### Task 6: Attendee history schema (migration 006)

**Files:**
- Create: `database/migrations/006_attendee_history.sql`

**Interfaces:**
- Produces: `feature_flags`, `feature_flag_overrides`, `attendee_history_opt_outs` tables, `locations.city` column, seeded rows for `attendee_history_view` and `attendee_history_hide_self`. Task 7 reads `feature_flags`/`feature_flag_overrides`; Task 8 reads/writes `attendee_history_opt_outs` and reads `location_checkins`.

- [ ] **Step 1: Write the migration**

```sql
-- 006: attendee history feature — flag system + opt-outs
alter table locations add column city text;

create table feature_flags (
  feature_name text primary key,
  default_enabled boolean not null default false,
  description text
);
alter table feature_flags enable row level security;
create policy "feature_flags_select" on feature_flags for select to authenticated using (true);

create table feature_flag_overrides (
  id uuid primary key default uuid_generate_v4(),
  feature_name text references feature_flags(feature_name) not null,
  scope_type text check (scope_type in ('city', 'location', 'user')) not null,
  scope_value text not null,
  enabled boolean not null,
  set_by uuid references profiles(id),
  set_at timestamptz default now(),
  unique(feature_name, scope_type, scope_value)
);
alter table feature_flag_overrides enable row level security;
create policy "feature_flag_overrides_select" on feature_flag_overrides for select to authenticated using (true);

create table attendee_history_opt_outs (
  user_id uuid references profiles(id) on delete cascade,
  location_id uuid references locations(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, location_id)
);
alter table attendee_history_opt_outs enable row level security;
create policy "opt_outs_select" on attendee_history_opt_outs for select to authenticated using (true);
create policy "opt_outs_insert" on attendee_history_opt_outs for insert to authenticated with check (user_id = auth.uid());
create policy "opt_outs_delete" on attendee_history_opt_outs for delete to authenticated using (user_id = auth.uid());

insert into feature_flags (feature_name, default_enabled, description) values
  ('attendee_history_view', false, 'View a venue''s all-time attendee roster'),
  ('attendee_history_hide_self', true, 'Allow a user to opt out of a venue''s attendee roster');
```

- [ ] **Step 2: Run it in the Supabase SQL Editor**

Paste and run. Expected: no errors. Confirm `feature_flags` has 2 rows, `locations` has a new `city` column (nullable, existing rows `null`).

- [ ] **Step 3: Commit**

```bash
git add database/migrations/006_attendee_history.sql
git commit -m "feat: add attendee history flag system schema (feature_flags, overrides, opt-outs)"
```

---

### Task 7: Flag resolver

**Files:**
- Create: `Wing Me/Classes/WAPFeatureFlags.swift`
- Test: `The W AppTests/WAPFeatureFlagsTests.swift`

**Interfaces:**
- Consumes: `WAPVenue` (Task 2), `WAPData.client` (existing).
- Produces: `WAPFeatureFlagOverride`, `WAPFeatureFlagDefault` models; `WAPFeatureFlagResolver.resolve(overrides:defaultEnabled:locationId:userId:city:) -> Bool` (pure function — Task 9/10 don't call this directly, they call `WAPData.resolveFeatureFlag` from Task 8, which wraps this).

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import The_W_App

final class WAPFeatureFlagsTests: XCTestCase {
    func testLocationOverrideWinsOverEverything() {
        let overrides = [
            WAPFeatureFlagOverride(featureName: "attendee_history_view", scopeType: "location", scopeValue: "loc-1", enabled: false),
            WAPFeatureFlagOverride(featureName: "attendee_history_view", scopeType: "user", scopeValue: "user-1", enabled: true),
            WAPFeatureFlagOverride(featureName: "attendee_history_view", scopeType: "city", scopeValue: "Austin", enabled: true),
        ]
        let result = WAPFeatureFlagResolver.resolve(
            overrides: overrides, defaultEnabled: true,
            locationId: "loc-1", userId: "user-1", city: "Austin"
        )
        XCTAssertFalse(result, "location override (false) must win over user/city overrides (true)")
    }

    func testUserOverrideWinsOverCityAndGlobal() {
        let overrides = [
            WAPFeatureFlagOverride(featureName: "attendee_history_view", scopeType: "user", scopeValue: "user-1", enabled: true),
            WAPFeatureFlagOverride(featureName: "attendee_history_view", scopeType: "city", scopeValue: "Austin", enabled: false),
        ]
        let result = WAPFeatureFlagResolver.resolve(
            overrides: overrides, defaultEnabled: false,
            locationId: "loc-1", userId: "user-1", city: "Austin"
        )
        XCTAssertTrue(result, "user override (true) must win over city override (false) and global default (false)")
    }

    func testCityOverrideWinsOverGlobal() {
        let overrides = [
            WAPFeatureFlagOverride(featureName: "attendee_history_view", scopeType: "city", scopeValue: "Austin", enabled: true),
        ]
        let result = WAPFeatureFlagResolver.resolve(
            overrides: overrides, defaultEnabled: false,
            locationId: "loc-1", userId: "user-1", city: "Austin"
        )
        XCTAssertTrue(result)
    }

    func testFallsBackToGlobalDefaultWhenNoOverridesMatch() {
        let result = WAPFeatureFlagResolver.resolve(
            overrides: [], defaultEnabled: true,
            locationId: "loc-1", userId: "user-1", city: nil
        )
        XCTAssertTrue(result)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" test -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:TheWAppTests/WAPFeatureFlagsTests`
Expected: FAIL — `WAPFeatureFlagOverride`/`WAPFeatureFlagResolver` don't exist yet.

- [ ] **Step 3: Write the implementation**

```swift
import Foundation

struct WAPFeatureFlagOverride: Codable {
    let featureName: String
    let scopeType: String
    let scopeValue: String
    let enabled: Bool

    enum CodingKeys: String, CodingKey {
        case featureName = "feature_name"
        case scopeType   = "scope_type"
        case scopeValue  = "scope_value"
        case enabled
    }
}

struct WAPFeatureFlagDefault: Codable {
    let featureName: String
    let defaultEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case featureName    = "feature_name"
        case defaultEnabled = "default_enabled"
    }
}

enum WAPFeatureFlagResolver {
    // Resolution order: location override > user override > city override > global default.
    static func resolve(
        overrides: [WAPFeatureFlagOverride],
        defaultEnabled: Bool,
        locationId: String,
        userId: String,
        city: String?
    ) -> Bool {
        if let locationOverride = overrides.first(where: { $0.scopeType == "location" && $0.scopeValue == locationId }) {
            return locationOverride.enabled
        }
        if let userOverride = overrides.first(where: { $0.scopeType == "user" && $0.scopeValue == userId }) {
            return userOverride.enabled
        }
        if let city, let cityOverride = overrides.first(where: { $0.scopeType == "city" && $0.scopeValue == city }) {
            return cityOverride.enabled
        }
        return defaultEnabled
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run the same `-only-testing:TheWAppTests/WAPFeatureFlagsTests` command. Expected: PASS, all 4 tests.

- [ ] **Step 5: Add the file to the Xcode target**

Same issue as the Phase 0 files — a new `.swift` file on disk isn't automatically in `project.pbxproj`. Add it via the `xcodeproj` gem (as used previously in this project):

```bash
cd /Users/sr/wingme-copy
ruby -e '
require "xcodeproj"
project = Xcodeproj::Project.open("The W App.xcodeproj")
target = project.targets.find { |t| t.name == "The W App" }
wing_me = project.main_group.children.find { |c| c.display_name == "Wing Me" }
classes = wing_me.children.find { |c| c.display_name == "Classes" }
ref = classes.new_file("WAPFeatureFlags.swift")
target.add_file_references([ref])
project.save
'
```

Also add `The W AppTests/WAPFeatureFlagsTests.swift` to the `The W AppTests` target the same way (find the test target/group by name instead of `"The W App"`/`"Classes"`).

- [ ] **Step 6: Commit**

```bash
git add "Wing Me/Classes/WAPFeatureFlags.swift" "The W AppTests/WAPFeatureFlagsTests.swift" "The W App.xcodeproj/project.pbxproj"
git commit -m "feat: add WAPFeatureFlagResolver — pure 4-level flag resolution (location>user>city>global)"
```

---

### Task 8: Attendee history data layer

**Files:**
- Modify: `Wing Me/Classes/WAPData.swift`

**Interfaces:**
- Consumes: `WAPFeatureFlagOverride`, `WAPFeatureFlagDefault`, `WAPFeatureFlagResolver` (Task 7); `WAPVenue` (Task 2); `WAPProfile` (existing).
- Produces: `WAPData.resolveFeatureFlag(featureName:userId:location:) async throws -> Bool`, `fetchAttendeeHistory(locationId:) async throws -> [WAPProfile]`, `setAttendeeHistoryOptOut(locationId:hidden:) async throws` — Task 9 (`AttendeeHistoryVC`) and Task 10 (entry-point wiring) call these three.

- [ ] **Step 1: Add the methods**

Append to `WAPData` in `Wing Me/Classes/WAPData.swift`:

```swift
    // MARK: - Attendee History

    func resolveFeatureFlag(featureName: String, userId: String, location: WAPVenue) async throws -> Bool {
        let overrides: [WAPFeatureFlagOverride] = try await client
            .from("feature_flag_overrides")
            .select()
            .eq("feature_name", value: featureName)
            .execute()
            .value
        let defaults: [WAPFeatureFlagDefault] = try await client
            .from("feature_flags")
            .select()
            .eq("feature_name", value: featureName)
            .execute()
            .value
        return WAPFeatureFlagResolver.resolve(
            overrides: overrides,
            defaultEnabled: defaults.first?.defaultEnabled ?? false,
            locationId: location.id,
            userId: userId,
            city: location.city
        )
    }

    func fetchAttendeeHistory(locationId: String) async throws -> [WAPProfile] {
        struct CheckinRow: Decodable { let profiles: WAPProfile }
        let rows: [CheckinRow] = try await client
            .from("location_checkins")
            .select("profiles(*)")
            .eq("location_id", value: locationId)
            .execute()
            .value
        struct OptOutRow: Decodable { let user_id: String }
        let optOuts: [OptOutRow] = try await client
            .from("attendee_history_opt_outs")
            .select("user_id")
            .eq("location_id", value: locationId)
            .execute()
            .value
        let optedOutIds = Set(optOuts.map(\.user_id))
        var seen = Set<String>()
        var result: [WAPProfile] = []
        for row in rows {
            let profile = row.profiles
            guard !optedOutIds.contains(profile.id), !seen.contains(profile.id) else { continue }
            seen.insert(profile.id)
            result.append(profile)
        }
        return result
    }

    func setAttendeeHistoryOptOut(locationId: String, hidden: Bool) async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        if hidden {
            struct OptOut: Encodable { let user_id: String; let location_id: String }
            try await client
                .from("attendee_history_opt_outs")
                .upsert(OptOut(user_id: uid, location_id: locationId))
                .execute()
        } else {
            try await client
                .from("attendee_history_opt_outs")
                .delete()
                .eq("user_id", value: uid)
                .eq("location_id", value: locationId)
                .execute()
        }
    }
```

- [ ] **Step 2: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add "Wing Me/Classes/WAPData.swift"
git commit -m "feat: add WAPData.resolveFeatureFlag/fetchAttendeeHistory/setAttendeeHistoryOptOut"
```

---

### Task 9: `AttendeeHistoryVC` screen

**Files:**
- Create: `Wing Me/New My Location/AttendeeHistoryVC.swift`

**Interfaces:**
- Consumes: `WAPData.shared.fetchAttendeeHistory(locationId:)`, `WAPData.shared.setAttendeeHistoryOptOut(locationId:hidden:)`, `WAPData.shared.resolveFeatureFlag` (Task 8); `WPillButton`, `Colors` (existing, from Phase 0); `WAPAuth.currentUserID` (existing); `UIImageView.imageFromServerURL(urlString:tableView:)` (existing, `Wing Me/Classes/Extensions.swift`).
- Produces: `AttendeeHistoryVC(locationId: String, locationName: String)` — a plain `UIViewController` with a `UITableView`, presentable from anywhere with a location context. Task 10 instantiates and presents it.

- [ ] **Step 1: Write the view controller**

```swift
import UIKit

final class AttendeeHistoryVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let locationId: String
    private let locationName: String

    private let tableView = UITableView()
    private let indicator = UIActivityIndicatorView(style: .medium)
    private var attendees: [WAPProfile] = []
    private var hideSelfEnabled = false
    private var isHidden = false

    init(locationId: String, locationName: String) {
        self.locationId = locationId
        self.locationName = locationName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.black
        title = "\(locationName) — Attendees"
        setupUI()
        Task { await load() }
    }

    private func setupUI() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AttendeeCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false

        [tableView, indicator].forEach { view.addSubview($0) }
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func load() async {
        indicator.startAnimating()
        defer { indicator.stopAnimating() }
        guard let uid = WAPAuth.currentUserID else { return }
        do {
            let venue = try await WAPData.shared.fetchVenue(id: locationId)
            hideSelfEnabled = try await WAPData.shared.resolveFeatureFlag(
                featureName: "attendee_history_hide_self", userId: uid, location: venue
            )
            attendees = try await WAPData.shared.fetchAttendeeHistory(locationId: locationId)
            tableView.reloadData()
        } catch {
            AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
        }
    }

    // own row (hide toggle) + one row per attendee
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        attendees.count + (hideSelfEnabled ? 1 : 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttendeeCell", for: indexPath)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        cell.detailTextLabel?.textColor = UIColor.white.withAlphaComponent(0.5)
        cell.imageView?.layer.cornerRadius = 18
        cell.imageView?.layer.masksToBounds = true
        cell.imageView?.backgroundColor = Colors.back_gray

        if hideSelfEnabled && indexPath.row == 0 {
            cell.textLabel?.text = "Hide me from this venue's history"
            cell.detailTextLabel?.text = isHidden ? "Hidden" : "Visible"
            let toggle = UISwitch()
            toggle.isOn = isHidden
            toggle.addTarget(self, action: #selector(toggleHide(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            return cell
        }

        let attendee = attendees[indexPath.row - (hideSelfEnabled ? 1 : 0)]
        cell.textLabel?.text = attendee.displayName
        cell.detailTextLabel?.text = nil
        cell.accessoryView = nil
        if let urlString = attendee.avatarURL {
            cell.imageView?.imageFromServerURL(urlString: urlString, tableView: tableView)
        }
        return cell
    }

    @objc private func toggleHide(_ sender: UISwitch) {
        let hidden = sender.isOn
        Task {
            do {
                try await WAPData.shared.setAttendeeHistoryOptOut(locationId: locationId, hidden: hidden)
                isHidden = hidden
            } catch {
                sender.isOn = !hidden
                AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
            }
        }
    }
}
```

- [ ] **Step 2: Add the file to the Xcode target**

```bash
cd /Users/sr/wingme-copy
ruby -e '
require "xcodeproj"
project = Xcodeproj::Project.open("The W App.xcodeproj")
target = project.targets.find { |t| t.name == "The W App" }
wing_me = project.main_group.children.find { |c| c.display_name == "Wing Me" }
new_my_location = wing_me.children.find { |c| c.display_name == "New My Location" }
ref = new_my_location.new_file("AttendeeHistoryVC.swift")
target.add_file_references([ref])
project.save
'
```

- [ ] **Step 3: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add "Wing Me/New My Location/AttendeeHistoryVC.swift" "The W App.xcodeproj/project.pbxproj"
git commit -m "feat: add AttendeeHistoryVC — all-time roster screen with per-venue hide toggle"
```

---

### Task 10: Wire the entry point into the venue screen

**Files:**
- Modify: `Wing Me/New My Location/NewMyLocationVC.swift`

**Interfaces:**
- Consumes: `AttendeeHistoryVC` (Task 9), `WAPData.shared.resolveFeatureFlag`/`fetchVenue` (Task 8/2), `WPillButton` (existing), `NewMyLocationVC.locationID` (existing property, line 30).

- [ ] **Step 1: Add the button and gating logic**

In `Wing Me/New My Location/NewMyLocationVC.swift`, add a property near the existing `var locationID = String()` (line 30):

```swift
    var locationID = String()
    private let attendeesButton = WPillButton()
```

In `viewDidLoad` (starts line 37), after the existing setup lines, add:

```swift
        setupAttendeesButton()
        Task { await refreshAttendeesButtonVisibility() }
```

Then add these two new methods to the class:

```swift
    private func setupAttendeesButton() {
        attendeesButton.setTitle("Attendees", for: .normal)
        attendeesButton.isHidden = true
        attendeesButton.addTarget(self, action: #selector(openAttendeeHistory), for: .touchUpInside)
        attendeesButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(attendeesButton)
        NSLayoutConstraint.activate([
            attendeesButton.topAnchor.constraint(equalTo: bannerView.bottomAnchor, constant: 8),
            attendeesButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            attendeesButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func refreshAttendeesButtonVisibility() async {
        guard !locationID.isEmpty, let uid = WAPAuth.currentUserID else { return }
        do {
            let venue = try await WAPData.shared.fetchVenue(id: locationID)
            let enabled = try await WAPData.shared.resolveFeatureFlag(
                featureName: "attendee_history_view", userId: uid, location: venue
            )
            attendeesButton.isHidden = !enabled
        } catch {
            attendeesButton.isHidden = true
        }
    }

    @objc private func openAttendeeHistory() {
        guard !locationID.isEmpty else { return }
        let vc = AttendeeHistoryVC(locationId: locationID, locationName: bannerLabel.text ?? "Venue")
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
```

- [ ] **Step 2: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Manual smoke test**

Run the app in Simulator (or have the user run it), navigate to a venue. Expected: "Attendees" button hidden by default (global default for `attendee_history_view` is `false` per Task 6's seed data). Insert a row in `feature_flag_overrides` via Supabase Table Editor: `feature_name='attendee_history_view', scope_type='location', scope_value='<that location's id>', enabled=true`. Reload the venue screen — button now appears; tapping it opens the roster.

- [ ] **Step 4: Commit**

```bash
git add "Wing Me/New My Location/NewMyLocationVC.swift"
git commit -m "feat: wire Attendees entry point into venue screen, gated by attendee_history_view"
```

---

## Verification

1. All 10 tasks committed, `xcodebuild ... build` succeeds at HEAD.
2. `xcodebuild ... test -only-testing:TheWAppTests/WAPModelsTests -only-testing:TheWAppTests/WAPFeatureFlagsTests` passes (5 tests total: 1 from Task 2, 4 from Task 7).
3. Manual: with `attendee_history_view` off (global default), no Attendees button on any venue screen. With a location override `enabled=true` for one venue, the button appears only there. With a user override `enabled=true` for a specific account (and location left unset), that account sees the button everywhere except venues with their own explicit override.
4. Manual: with `attendee_history_hide_self` on (global default), the hide toggle appears as the first row in the roster; toggling it on removes your own profile from the roster on next load (test with a second account, or re-fetch and confirm your `id` isn't in the returned list).
5. Manual: RLS — confirm a non-owner user cannot `INSERT`/`UPDATE`/`DELETE` on `feature_flags` or `feature_flag_overrides` via the Supabase client (only `SELECT` should succeed; writes happen through the Table Editor, which uses the service role and bypasses RLS).

## Known Deferred
- Native in-app admin UI for `feature_flags`/`feature_flag_overrides` — explicitly out of scope per the spec; managed via Supabase Table Editor.
- Connections feature (contact sync, connection-scoped history, live-location sharing consent) — separate future brainstorm, not part of this plan.
- `KeychainHelperTests.swift`/`WAPAuthTests.swift` importing `TheWApp` instead of `The_W_App` — pre-existing, unrelated bug, noted but not fixed here.
