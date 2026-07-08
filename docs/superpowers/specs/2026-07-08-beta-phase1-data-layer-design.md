# Beta Phase 1 — Finish Data-Layer Reconciliation (Rewards + Feed)

## Context

This is Phase 1 of a 6-phase roadmap toward a public TestFlight/App Store beta (see chat history for the full phase list; this spec covers only Phase 1). Earlier this session, `WAPData.swift`/`WAPModels.swift` were reconciled against the real Supabase schema for profiles, venues, presence, and contacts. The final whole-branch review of that work flagged two more mismatches, left unfixed because nothing called them yet: `WAPReward`/`fetchRewards` and `WAPFeedItem`/`fetchFeed`/`postToFeed` still target column names (`venue_id`, `tier`, `type`, `title`, `text`) that don't exist on the real `rewards` and `feed_posts` tables. This spec closes that gap — the last piece of Phase 0/pre-beta schema debt — so every `WAPData` method actually works against the live database before later phases build UI on top of them.

This is a mechanical reconciliation, not new feature design, with one real decision: `rewards` has no `tier` column, but the design docs describe a "Prem | Key | Features" segmented Rewards screen. Resolved: tier is *derived*, not stored — a reward optionally references a `feature_unlocks.feature_name`; unlinked rewards are "Key" (free/always visible), linked ones are "Prem" (visible only if the user has that feature unlocked via the existing points system). No new UI in this phase — just the data layer, so the Phase 5 Rewards screen has a correct foundation to build on.

## Data Model

```sql
-- 007: reward tiering via feature_unlocks reference
alter table rewards add column if not exists feature_name text references feature_unlocks(feature_name);
```

No other schema changes — `feed_posts` and the rest of `rewards` already match what's needed once the Swift models are corrected.

## Rewards

Replace `WAPReward` (currently: `id, venueId, type, title, description, verificationInstructions, tier`) with a struct matching the real `rewards` columns:

```swift
struct WAPReward: Codable, Identifiable {
    let id: String
    let locationId: String
    var name: String
    var iconType: String?
    var dealText: String?
    var instructions: String?
    var qrPath: String?
    var isActive: Bool
    var displayOrder: Int
    var featureName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case locationId   = "location_id"
        case name
        case iconType     = "icon_type"
        case dealText     = "deal_text"
        case instructions
        case qrPath       = "qr_path"
        case isActive     = "is_active"
        case displayOrder = "display_order"
        case featureName  = "feature_name"
    }
}
```

`WAPData.fetchRewards(venueId:tier:)` → `fetchRewards(locationId:) async throws -> [WAPReward]`: selects all rewards for `location_id`, filtered to `is_active = true`, ordered by `display_order`. Drops the `tier` parameter — tiering is now a property on the returned rewards (`featureName == nil` means Key/free), not a query filter, so callers can bucket client-side.

Add `WAPData.hasFeatureAccess(featureName: String) async throws -> Bool`: checks whether the current user has a row in `user_feature_access` for that `feature_name`. Used by a future Rewards screen to decide whether to show a Prem-tier reward as unlocked or locked — not consumed by anything in this phase, but the natural, minimal companion to `featureName` on `WAPReward`.

## Feed

Replace `WAPFeedItem` (currently: `id, venueId, userId, text, createdAt, profile`) with:

```swift
struct WAPFeedItem: Codable, Identifiable {
    let id: String
    let locationId: String
    let userId: String
    var content: String
    var zoneTag: String?
    var createdAt: String
    var profile: WAPProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case locationId = "location_id"
        case userId     = "user_id"
        case content
        case zoneTag    = "zone_tag"
        case createdAt  = "created_at"
        case profile    = "profiles"
    }
}
```

`fetchFeed(venueId:)` → `fetchFeed(locationId:) async throws -> [WAPFeedItem]`: same query shape, targeting `location_id`. `postToFeed(venueId:text:)` → `postToFeed(locationId:text:)`: keeps the external parameter name `text:` (a fine public API name, matches how `WAPProfile.displayName` doesn't literally match `display_name`), inserts it into the `content` column.

## Non-Goals

- No claim flow (`reward_claims` insert/fetch) — belongs to the Phase 5 Rewards screen when the claim UI is actually built.
- No Feed UI changes — `fetchFeed`/`postToFeed` aren't called from any screen yet (Main Feed rebuild is Phase 3); this only fixes the data layer they'll eventually use.
- No changes to `feed_reactions` — untouched by this phase, not referenced by any existing `WAPData` method.

## Manual Follow-Up (not part of the implementation plan — human does this)

Run in the Supabase SQL Editor, in order: `004_profile_columns.sql`, `005_rls_policy_fixes.sql`, `006_attendee_history.sql` (none have been run yet, all idempotent), then the new `007_reward_tiering.sql` from this phase.
