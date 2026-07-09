# Beta Phase 3 — Wire Main Feed to Real Data (Feed + Presence Only)

## Context

`NewMyLocationVC` (the "winged into a venue" screen) is still entirely PHP-backed. It bundles venue info and feed comments into one `get_location.php` call, fetches "who's here" via `get_users.php`, and checks in/out via `wing_on.php`/`wing_off.php`. This spec covers swapping those five calls for the now-correct `WAPData` methods (fixed against the real schema in Phase 1). No new UI, no tab structure, no likes/badges/replies/chat — those are either explicitly out of scope or a future phase.

## Data Mapping

**Venue + banner:** `getLocation()`'s venue portion (name, banner images, welcome message) maps to `WAPData.fetchVenue(id: locationID) -> WAPVenue`. `WAPVenue` has `name`, `bannerImage` (single image, not the PHP response's array-of-banners) — the existing multi-banner carousel collapses to a single banner image for now; `bannerArray` gets one `BannerStruct` built from `WAPVenue.bannerImage` instead of iterating a PHP array. `isMaster`/`isOwner` (admin flags from the old response) have no `WAPVenue` equivalent — default both to `false`; nothing in this phase's scope depends on them being accurate.

**Feed:** a separate call to `WAPData.fetchFeed(locationId: locationID) -> [WAPFeedItem]`, mapped into the existing `CommentStruct` the table view already renders:

| `CommentStruct` field | Source | Note |
|---|---|---|
| `id` | `item.id` | |
| `userID` | `item.userId` | |
| `name` | `item.profile?.displayName ?? ""` | |
| `city` | `item.profile?.city ?? ""` | |
| `comment` | `item.content` | |
| `imageView` | loaded from `item.profile?.avatarURL` via the existing `imageFromServerURL(urlString:tableView:)` | |
| `isMyComment` | `item.userId == WAPAuth.currentUserID` | |
| `age`, `gender`, `country` | `""` | no backing field on `WAPProfile` — real but contained regression, not a crash |
| `likes` | `0` | no reaction-fetching in `WAPData` yet |
| `isLiked` | `false` | same |
| `badgeTitle`, `badgeImageView` | `""` / empty `UIImageView()` | badges are a separate, untouched system |

**Posting:** `send()`'s `addComment()` call maps to `WAPData.postToFeed(locationId: locationID, text: commentTextField.getText())`. On success, prepend the new item to `commentsArray` (constructed the same way as fetched items, using the current user's own cached profile for the avatar/name — no need to re-fetch the whole feed) and reload the table, matching the existing optimistic-update pattern.

**Presence ("who's here"):** `getUsers()` maps to `WAPData.fetchPresence(locationId: locationID) -> [WAPPresence]`. The existing `usersArray: [CustomCell]` (rendered via `LocationPersonCell`) is a generic two-field struct — map each `WAPPresence` to `CustomCell(string1: presence.userId, string2: presence.profile?.displayName ?? "")`. (Implementer: grep `LocationPersonCell`'s actual cell-configuration code first to confirm exactly which of `string1`/`string2` it reads before finalizing this mapping — the two-field shape is confirmed from `NewMyLocationVC`'s existing table view setup, but the cell's internal usage should be double-checked against the live code, not assumed from this summary.)

**Check-in / check-out:** `wingIn()` (the no-argument version, called from `wingIn(customCell:)`) maps to `WAPData.checkIn(locationId: locationID)`. `wingOut(_:)`'s action-sheet confirm handler (currently just clears local state via `hideLocation()`) also calls `WAPData.checkOut(locationId: locationID)` before clearing state, so the venue's `location_checkins` row actually gets closed out server-side — this is a real fix, not just a rename, since the current PHP-era flow doesn't appear to call `wing_off.php` from this exact path either (worth the implementer double-checking `hideLocation()`'s full body for any existing `wing_off.php` call that might already be doing this, to avoid a double-checkout).

## Non-Goals

- No likes/reactions, badges, replies, or in-comment chat — all stay on their current (unchanged, still-PHP) path.
- No multi-banner carousel from `WAPVenue` — single banner image only, matching what the model actually has.
- No new tab structure (WHO'S HERE / CONNECTIONS) — this phase reuses the existing single-feed-view layout.
- No changes to `ReplyVC`, `BadgesVC`, `ChatVC`, or the delete-comment/delete-like flows.
