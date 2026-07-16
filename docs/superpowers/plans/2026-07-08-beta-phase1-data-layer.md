# Beta Phase 1 — Data-Layer Reconciliation (Rewards + Feed) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Apply the `ponytail` skill's YAGNI discipline — no claim-flow UI, no feed UI, this phase is data-layer only.

**Goal:** Fix `WAPReward`/`fetchRewards` and `WAPFeedItem`/`fetchFeed`/`postToFeed` to target the real `rewards` and `feed_posts` schema, closing the last piece of pre-beta schema debt, per `docs/superpowers/specs/2026-07-08-beta-phase1-data-layer-design.md`.

**Architecture:** Same reconciliation pattern already used this session for profiles/venues/presence/contacts — reshape the Swift model's fields/CodingKeys to match real columns, fix the table name and query shape in `WAPData`, grep for callers and fix any found. One new migration (`007`) adds a nullable `feature_name` column to `rewards` for derived tiering.

**Tech Stack:** Swift 5, UIKit, Supabase Swift SDK 2.50.0, Supabase Postgres/RLS.

## Global Constraints

- Open `The W App.xcworkspace`, never `.xcodeproj`.
- Verify each Swift task by running a full build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build` from `/Users/sr/thewapp-copy`.
- This project has no functional XCTest target (known, pre-existing, separate issue) — no test files are part of this plan, verification is build-only.
- SQL migrations are numbered sequentially — this plan's migration is `007`, following the existing `001`-`006`. It has not been run against Supabase yet, so it's safe to edit directly if a fix is needed later.

---

### Task 1: Reward tiering migration

**Files:**
- Create: `database/migrations/007_reward_tiering.sql`

**Interfaces:**
- Produces: `rewards.feature_name` (nullable, references `feature_unlocks.feature_name`) — Task 2's `WAPReward` model reads this column.

- [ ] **Step 1: Write the migration**

```sql
-- 007: reward tiering via feature_unlocks reference
alter table rewards add column if not exists feature_name text references feature_unlocks(feature_name);
```

- [ ] **Step 2: Run it in the Supabase SQL Editor**

This is a MANUAL action for the human — paste and run in the Supabase SQL Editor after `004`, `005`, `006` (none of which have been run yet either). Not something the implementer subagent can do (no database credentials/access).

- [ ] **Step 3: Commit**

```bash
cd /Users/sr/thewapp-copy
git add database/migrations/007_reward_tiering.sql
git commit -m "feat: add rewards.feature_name column for derived reward tiering"
```

---

### Task 2: Fix rewards data layer

**Files:**
- Modify: `The W App/Classes/WAPModels.swift` (the `WAPReward` struct, currently at line 112)
- Modify: `The W App/Classes/WAPData.swift` (`fetchRewards`, currently at line 137; add `hasFeatureAccess`)

**Interfaces:**
- Consumes: `rewards.feature_name` (Task 1).
- Produces: `WAPReward(id, locationId, name, iconType, dealText, instructions, qrPath, isActive, displayOrder, featureName)`; `WAPData.fetchRewards(locationId:) async throws -> [WAPReward]`; `WAPData.hasFeatureAccess(featureName: String) async throws -> Bool`. Not consumed by anything in this plan — the Phase 5 Rewards screen will use them later.

- [ ] **Step 1: Replace `WAPReward`**

In `The W App/Classes/WAPModels.swift`, replace the existing `WAPReward` struct:

```swift
struct WAPReward: Codable, Identifiable {
    let id: String
    let venueId: String?
    var type: String
    var title: String
    var description: String?
    var verificationInstructions: String?
    var tier: String

    enum CodingKeys: String, CodingKey {
        case id
        case venueId                  = "venue_id"
        case type
        case title
        case description
        case verificationInstructions = "verification_instructions"
        case tier
    }
}
```

with:

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

- [ ] **Step 2: Fix `fetchRewards` and add `hasFeatureAccess`**

In `The W App/Classes/WAPData.swift`, replace:

```swift
    func fetchRewards(venueId: String, tier: String) async throws -> [WAPReward] {
        try await client
            .from("rewards")
            .select()
            .eq("venue_id", value: venueId)
            .eq("tier", value: tier)
            .execute()
            .value
    }
```

with:

```swift
    func fetchRewards(locationId: String) async throws -> [WAPReward] {
        try await client
            .from("rewards")
            .select()
            .eq("location_id", value: locationId)
            .eq("is_active", value: true)
            .order("display_order")
            .execute()
            .value
    }

    func hasFeatureAccess(featureName: String) async throws -> Bool {
        guard let uid = WAPAuth.currentUserID else { return false }
        struct AccessRow: Decodable { let user_id: String }
        let rows: [AccessRow] = try await client
            .from("user_feature_access")
            .select("user_id")
            .eq("user_id", value: uid)
            .eq("feature_name", value: featureName)
            .execute()
            .value
        return !rows.isEmpty
    }
```

- [ ] **Step 3: Check for callers**

Run: `grep -rn "fetchRewards(venueId\|WAPReward" "The W App" --include="*.swift"` from `/Users/sr/thewapp-copy`. Expected today: only `WAPModels.swift` and `WAPData.swift` (nothing in the UI calls this yet, per the final review that flagged this as latent/unused code) — if any other file appears, update it to use the new `locationId:` signature and field names.

- [ ] **Step 4: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add "The W App/Classes/WAPModels.swift" "The W App/Classes/WAPData.swift"
git commit -m "fix: WAPReward and fetchRewards target real rewards columns, add hasFeatureAccess for derived tiering"
```

---

### Task 3: Fix feed data layer

**Files:**
- Modify: `The W App/Classes/WAPModels.swift` (the `WAPFeedItem` struct, currently at line 56)
- Modify: `The W App/Classes/WAPData.swift` (`fetchFeed`, currently at line 54; `postToFeed`, currently at line 65)

**Interfaces:**
- Produces: `WAPFeedItem(id, locationId, userId, content, zoneTag, createdAt, profile)`; `WAPData.fetchFeed(locationId:) async throws -> [WAPFeedItem]`; `WAPData.postToFeed(locationId:text:) async throws`. Not consumed by anything in this plan — the Phase 3 Main Feed rebuild will use them later.

- [ ] **Step 1: Replace `WAPFeedItem`**

In `The W App/Classes/WAPModels.swift`, replace the existing `WAPFeedItem` struct:

```swift
struct WAPFeedItem: Codable, Identifiable {
    let id: String
    let venueId: String
    let userId: String
    var text: String
    var createdAt: String
    var profile: WAPProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case venueId   = "venue_id"
        case userId    = "user_id"
        case text
        case createdAt = "created_at"
        case profile   = "profiles"
    }
}
```

with:

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

- [ ] **Step 2: Fix `fetchFeed` and `postToFeed`**

In `The W App/Classes/WAPData.swift`, replace:

```swift
    func fetchFeed(venueId: String) async throws -> [WAPFeedItem] {
        try await client
            .from("feed_posts")
            .select("*, profiles(*)")
            .eq("venue_id", value: venueId)
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value
    }

    func postToFeed(venueId: String, text: String) async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        struct Post: Encodable {
            let venue_id: String
            let user_id: String
            let text: String
        }
        try await client
            .from("feed_posts")
            .insert(Post(venue_id: venueId, user_id: uid, text: text))
            .execute()
    }
```

with:

```swift
    func fetchFeed(locationId: String) async throws -> [WAPFeedItem] {
        try await client
            .from("feed_posts")
            .select("*, profiles(*)")
            .eq("location_id", value: locationId)
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value
    }

    func postToFeed(locationId: String, text: String) async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        struct Post: Encodable {
            let location_id: String
            let user_id: String
            let content: String
        }
        try await client
            .from("feed_posts")
            .insert(Post(location_id: locationId, user_id: uid, content: text))
            .execute()
    }
```

- [ ] **Step 3: Check for callers**

Run: `grep -rn "fetchFeed(venueId\|postToFeed(venueId\|WAPFeedItem" "The W App" --include="*.swift"` from `/Users/sr/thewapp-copy`. Expected today: only `WAPModels.swift` and `WAPData.swift` — if any other file appears, update it to use the new `locationId:` parameter label.

- [ ] **Step 4: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add "The W App/Classes/WAPModels.swift" "The W App/Classes/WAPData.swift"
git commit -m "fix: WAPFeedItem and fetchFeed/postToFeed target real feed_posts columns"
```

---

## Verification

1. All 3 tasks committed, `xcodebuild ... build` succeeds at HEAD.
2. Manual: `007_reward_tiering.sql` run in Supabase SQL Editor after `004`-`006` (also still pending from the attendee-history phase).
3. `grep -rn "venue_id\|\.venueId\b" "The W App/Classes/WAPModels.swift" "The W App/Classes/WAPData.swift"` returns zero hits related to rewards/feed (some `venueId`/`venue_id` may legitimately remain elsewhere if any other domain still uses it — check context).

## Known Deferred
- Reward claim flow (`reward_claims`) — Phase 5.
- Feed UI — Phase 3.
- `hasFeatureAccess` and `WAPReward.featureName` are unconsumed until Phase 5 builds the Rewards screen.
