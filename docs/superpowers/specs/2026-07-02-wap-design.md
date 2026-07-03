# The W App (WAP) — Design Spec
**"When and Where"**
Date: 2026-07-02

---

## Overview

WAP is an iOS networking app for conferences and business/industry events. It helps people connect who are already in the same location — through a WHO mechanic (share who you are to see who's there), QR-based contact exchange, a live social feed, and a gamified engagement bar that unlocks premium features.

Forked from `wingme-copy` (UIKit/Swift), backend replaced with Supabase.

---

## 1. Architecture & Tech Stack

- **iOS**: Swift/UIKit, CocoaPods, Supabase Swift SDK (replaces all URLSession/PHP calls)
- **Auth**: Phone OTP + Apple Sign In + Facebook via Supabase Auth — token stored in Keychain
- **Database**: Supabase Postgres with Row Level Security
- **Real-time**: Supabase Realtime on `location_checkins` and `feed_posts`
- **Storage**: Supabase Storage — buckets: `avatars`, `banners`, `qr-assets`
- **Maps**: Google Maps iOS SDK + Places API for location search/add; iOS `CLLocationManager` + `CLCircularRegion` for geofencing
- **Haptics/Audio**: `UIImpactFeedbackGenerator` + `AVFoundation` for engagement bar feedback
- **Removed from Wing Me**: PHP URLSession calls, wingme.app backend, dating fields (relationship status, looking for love), UserDefaults token storage

---

## 2. Database Schema

### Core Profile

| Table | Key Columns |
|---|---|
| `profiles` | id (→ auth.users), name, photo_url, city, industry — core only, never removable |
| `profile_field_definitions` | id, label, field_type (text/dropdown/number), is_global, location_id (null=global), display_order, is_active |
| `profile_field_values` | user_id, field_definition_id, value, is_visible |
| `profile_images` | user_id, storage_path, is_banner, is_avatar, display_order |

Default global fields (configurable via admin): Age, Fave Drink, Nationality, Bio, On Friday Night I…

### Social & Location

| Table | Key Columns |
|---|---|
| `locations` | id, name, address, lat, lng, geofence_radius_meters, owner_id, is_event, event_date, banner_image |
| `location_checkins` | id, user_id, location_id, mode (live/peeking), checked_in_at, checked_out_at |
| `friendships` | user_id, friend_id, connected_at, source (qr_scan/peek_invite/message) |
| `peek_invites` | id, sender_id, peeker_id, location_id, sent_at, accepted_at |
| `feed_posts` | id, user_id, location_id, content, zone_tag, created_at |
| `feed_reactions` | id, post_id, user_id, reaction_type |

### Connections & Tracking

| Table | Key Columns |
|---|---|
| `connections` | id, scanner_id, scannee_id, location_id, scanned_at |
| `contact_methods` | id, user_id, slot_order, type (whatsapp/linkedin/facebook/instagram/phone/link), value, is_enabled |
| `contact_taps` | id, connection_id, method_type, tapped_at |

### Rewards & Gamification

| Table | Key Columns |
|---|---|
| `rewards` | id, location_id, reward_type, deal_text, instructions, qr_path, is_active |
| `reward_claims` | id, user_id, reward_id, claimed_at, verified_by |
| `engagement_events` | id, user_id, event_type, points_earned, created_at |
| `feature_unlocks` | id, feature_name, points_required, description |
| `user_feature_access` | id, user_id, feature_name, unlocked_at, granted_by (null=earned) |

### Verification & Custom Fields

| Table | Key Columns |
|---|---|
| `verification_tags` | id, user_id, location_id, tag (Host/Waiter/Bartender/Chef/Events/Other/custom), assigned_by |

---

## 3. Onboarding & WHO Mechanic

### Sign-Up Flow (hard gates — cannot skip)

1. Sign up — phone OTP / Apple / Facebook
2. Add profile photo — camera or gallery, uploaded before advancing
3. Basic info — Name, Age, Profession/Industry, City
4. Add at least 1 contact method
5. Grant precise location — system prompt; if denied, screen stays with explanation + deep-link to Settings

### Main Feed Unlock

Feed is blurred until user has at least 1 friend on the app:
- "Sync Contacts" — matches phone contacts against `profiles`, notifies user on match
- "Invite Friends" — native iOS share sheet with app link

### Screens Reused from Wing Me

`RegisterVC`, `FcbRegisterVC`, `First–FifthSetupVC` (remapped to 4 steps), `WelcomeVC`, `FirstStartVC`, `SecondStartVC`

---

## 4. Main Feed — 3 States

### Top Card (always visible)
- Browse nearby locations — queries `locations` by GPS proximity
- Add this location → Google Maps Places search, user pins, geofence auto-generated (default 100m venues / 300m large spaces), user becomes owner

### State 1 — Not Checked In
- Feed shows friends' current or last known location + timestamp
- Pending peek invites surface here
- Blurred with sync/invite CTAs if no friends yet

### State 2 — Peeking
- Available to all users with a completed profile
- User taps a location from browse list → peek mode (one active at a time)
- Same feed layout as State 3 but names + photos blurred; industry + nationality readable
- User's grey card appears on that location's live feed with their distance from venue
- Attendees can view peeker's full profile (except current location)
- Attendees can invite peeker → invite lands in peeker's home feed
- Accepted invite → mutual full visibility between those two only
- Switching locations cancels current peek and clears unresponded invites

### State 3 — Live
- Geofence entry → "Are you at [name]? Check in" prompt → sets mode to `live`
- Full co-attendee cards with real-time updates (Supabase Realtime)
- Sub-nav: Music icon | WHO'S HERE | Photo Booth icon (Music + Photo Booth = v2)
- Zone filter pills: All / Bar / Main Stage / Breakout A / etc.
- Venue owner posts pinned at top
- Bottom compose bar: "Share whatever where ever…" → `feed_posts` with optional zone tag
- All posts show relative timestamps ("2 mins ago", "5h ago")
- Geofence exit → auto check-out after 15-minute grace period

---

## 5. Profile + QR + Contact Methods

### Profile Screen
- Swipeable banner (up to 3 images) + circular avatar overlaid bottom-center
- Name + blue verified checkmark + role/title
- Intent emoji row: ❤️ 💼 🤝 (up to 3 selected — Love / Business / Networking)
- Core fields: Name, Photo, Industry, City (always shown)
- Configurable fields rendered from `profile_field_definitions` (active global + event-specific)
- Each configurable field has eye toggle (visible/hidden) — free in v1
- "links" button → Contact Methods screen
- `+` button → if owner, opens Verification Tag assignment sheet

### Contact Methods Screen
- 2×3 grid: WhatsApp, LinkedIn, Facebook, Instagram, Phone, Link
- **Base: 2 slots active** — additional slots unlocked via engagement bar (see Section 8)
- Tap any enabled slot → full-screen QR expand + native share icon
- Edit mode: URL/number input + enable toggle per slot
- Every QR share → `connections` row; every method tap → `contact_taps` row

---

## 6. Wing In History

Clock icon in quick access row.

- List of all past locations the user has checked into
- Tap a location → social feed archive grouped by Date + Event Type
- Each entry: avatar, name, status quote, relative timestamp, reaction count
- Searchable and sortable
- Query: `location_checkins` joined to `feed_posts` by location_id + date range

---

## 7. Rewards

Trophy icon in quick access row. Two tabs:

### Activity
Event-scoped challenges defined by organizer (meet vendors, scan QR codes, find industry matches). Basic in v1.

### Premium Features
Business users (location/event owners) have **full control** over their rewards via the admin portal — same editability pattern as profile fields.

**9 preset template types** (starting suggestions, not hard limits):

| Row | Types |
|---|---|
| 1 | BOGO · Ticket · Discount |
| 2 | Party · Badge · Dining |
| 3 | Valet · VIPx · Drinks |
| 4 | + · + · + (custom) |

**What business users can do in admin portal → Rewards tab:**
- Create a reward from a template or from scratch
- Edit any reward: name, deal text (D), instructions (I), icon type, QR code
- Activate / deactivate rewards
- Reorder display order
- Delete rewards

**Schema update:**

| Table | Key Columns |
|---|---|
| `rewards` | id, location_id, name, icon_type (preset enum or custom), deal_text, instructions, qr_path, is_active, display_order, created_by |

**User flow:** Tap reward → see D + I + QR → staff scans QR → `reward_claims` row created + engagement points awarded.

---

## 8. Engagement Bar System

Thin bar pinned at the very top of every screen. Lifetime cumulative — never resets.

### Point-Earning Actions

| Action | Points |
|---|---|
| Add profile photo | 50 |
| Add contact method slot | 20 each |
| Complete a profile field | 10 each |
| Check in to a location | 25 |
| Post to live feed | 15 |
| Make a QR connection | 30 |
| Accept a peek invite | 20 |
| Claim a reward | 25 |
| Add a friend | 20 |
| Receive a contact method tap | 10 |

### Feature Unlock Milestones

| Level | Points | Unlocks |
|---|---|---|
| 1 | 100 | 3rd + 4th contact method slot |
| 2 | 250 | Map view |
| 3 | 500 | 5th + 6th contact method slot |
| 4 | 1000 | Anonymous peek mode (browse without your grey card appearing on their feed) |
| 5 | 2000 | Extended history + custom field access |

### Feedback on Every Action
- Casino sound effect (AVFoundation)
- Haptic burst (UIImpactFeedbackGenerator — .medium impact)
- Spring fill animation on the bar toward next milestone

### Admin Override
Location owner can grant any user instant access to any feature regardless of points via `user_feature_access.granted_by`.

---

## 9. Messaging & Inbox

Bottom nav right tab. Carried over from Wing Me and rewired to Supabase:
- `MessagesVC` — conversation list
- `ChatVC` — direct messages
- `GroupChatVC` — group conversations

Push notifications via Supabase Realtime. UI kept as-is for v1.

---

## 10. Verification Tags & Custom Profile Fields

### Verification Tags
Owner taps `+` on any attendee profile → sheet: Host / Waiter / Bartender / Chef / Events / Other (free text). Displayed as badge next to name on profile + feed cards. Stored in `verification_tags`.

### Custom Profile Fields
Managed by location/event owner in admin portal "Profile Fields" tab:
- Add field: label, type (text/dropdown/number), required toggle
- Remove or deactivate fields
- Drag to reorder
- Stored in `profile_field_definitions` (location_id set); values in `profile_field_values`
- Free in v1 — freemium governance future

---

## 11. Admin Portal

In-app `WKWebView` → Supabase-hosted dashboard. Location owners only.

| Tab | Content |
|---|---|
| Overview | Total check-ins, QR connections, peek→live conversion rate |
| Connections | Contact method taps by type, connection log |
| Rewards | Claims by type, pending verifications |
| Profile Fields | Add/remove/reorder configurable profile fields for this event |
| Attendees | Checked-in user list, grant feature access overrides, assign verification tags |
| Engagement | Top engaged attendees leaderboard |

---

## 12. Navigation

**Bottom tab bar (3 tabs):**
- Left: Location pin → Map view (unlocked at Level 2 / 250pts)
- Center: W logo → Main feed
- Right: Inbox icon → Messaging

**Quick access row (above main feed area):**
- History (clock icon)
- Rewards (trophy icon)
- Profile (person icon)

---

## 13. Out of Scope — v1

- Photo booth
- Music / song request
- Freemium billing / payment flows
- Global WAP platform admin panel (managed via Supabase dashboard directly)
- Vendor/product screen

---

## 14. Wing Me → WAP Migration Notes

**Removed:** all ~55 PHP endpoint URLSession calls, relationship status fields, "looking for" categories, UserDefaults token storage, wingme.app URLs, dating-specific logic

**Reused and rewired to Supabase:** Auth VCs, profile setup VCs, messaging VCs (`MessagesVC`, `ChatVC`, `GroupChatVC`), QR code VCs (`QRCodeVC`, `MyLinksVC`, `UserLinksVC`), image caching, `LocationManager`, `NotificationVC`, `BlockListVC`

**Key string replacements:**
- `wingOut` → "Check In"
- `alertWingout` → "You need to check in first"
- All "Wing" terminology → WAP equivalents

**Key constant replacements:**
- `Constants.url` → Supabase project URL
- `https://wingme.app/` → WAP app URL
- UserDefaults keys: Token → Keychain, dating-specific keys removed
