# Beta Phase 3 — Wire Main Feed to Real Data Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Apply the `ponytail` skill's YAGNI discipline — no new UI, no tabs, no likes/badges/replies/chat wiring; those stay exactly as they are today.

**Goal:** Replace `NewMyLocationVC`'s PHP calls for venue/feed/presence/check-in/check-out/posting with the corresponding `WAPData` methods, per `docs/superpowers/specs/2026-07-09-beta-phase3-feed-presence-design.md`.

**Architecture:** Task 1 replaces the two read paths (venue+feed via `getLocation()`, presence via `getUsers()`), both triggered from `reload()`. Task 2 replaces the three write paths (`wingIn()`, `wingOff()`, `addComment()`). The `locationID.contains("Event")` branch — a separate, still-PHP-backed code path for event locations — is preserved exactly as-is in every function; only the non-event branches are replaced.

**Tech Stack:** Swift 5, UIKit, Supabase Swift SDK 2.50.0.

## Global Constraints

- Open `The W App.xcworkspace`, never `.xcodeproj`.
- Verify each task with a full build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build` from `/Users/sr/wingme-copy`.
- No functional XCTest target exists (known, pre-existing) — verification is build-only.
- Do not touch `getEvent()`/`eventSuccess()`/`eventStopLoading()` or any `locationID.contains("Event")` branch's PHP call — event locations stay on the old path entirely, unchanged.
- Do not touch `openReplies`/`openBadges`/`openChat`/`addLike`/`deleteLike`/`deleteComment`/badge assignment methods, or any other method not explicitly listed in a task below.
- Confirmed via grep this session: `getLocation`, `getUsers`, `wingIn()` (no-arg), `wingOff()`, `addComment()` have no callers outside `Wing Me/New My Location/NewMyLocationVC.swift` — safe to restructure their internals freely as long as the method names stay the same (other code may still reference them by name, e.g. `reload()` calling them).

---

### Task 1: Wire venue, feed, and presence loading

**Files:**
- Modify: `Wing Me/New My Location/NewMyLocationVC.swift` (`getLocation()`/`locationStopLoading()`/`locationSuccess()`, `getUsers()`/`usersStopLoading()`/`usersSuccess()`; `reload()` is unchanged and shown only for context)

**Interfaces:**
- Consumes: `WAPData.shared.fetchVenue(id:)`, `.fetchFeed(locationId:)`, `.fetchPresence(locationId:)` (existing, from Phase 1); `WAPAuth.currentUserID` (existing); `CommentStruct`, `BannerStruct`, `CustomCell` (existing, unchanged shapes); `imageFromServerURL(urlString:tableView:)`/`(urlString:collectionView:)` (existing, `Wing Me/Classes/Extensions.swift`).

- [ ] **Step 1: Replace the six methods**

`reload()` itself does not change — shown below only so the implementer can locate the right place in the file; do not duplicate it:

```swift
    @objc func reload() {
        guard let _ = UserDefaults.standard.object(forKey: "Token") else {
            return
        }
        if (!inLocation) {
            return
        }
        indicator.startAnimating()
        
        if locationID.contains("Event") {
            getEvent()
        } else {
            getLocation()
            getUsers()
        }
    }
```

Replace the six methods `getLocation()`, `locationStopLoading()`, `locationSuccess(jsonObject:)`, `getUsers()`, `usersStopLoading()`, `usersSuccess(jsonObject:)` (originally spanning roughly lines 461–623, the PHP-based versions) with:

```swift
    func getLocation() {
        Task {
            do {
                let venue = try await WAPData.shared.fetchVenue(id: locationID)
                await MainActor.run { self.locationSuccess(venue: venue) }
            } catch {
                await MainActor.run {
                    self.locationStopLoading()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    func locationStopLoading() {
        indicator.stopAnimating()
    }

    func locationSuccess(venue: WAPVenue) {
        isMaster = false
        isOwner = false

        bannerArray = []
        commentsArray = []

        if let bannerImageURLString = venue.bannerImage, !bannerImageURLString.isEmpty {
            let bannerImageView = UIImageView()
            bannerImageView.imageFromServerURL(urlString: bannerImageURLString, collectionView: collectionView)
            bannerArray.append(BannerStruct(imageView: bannerImageView, title: "", url: "", blurred: false))
        }
        collectionView.reloadData()
        pageControl.numberOfPages = bannerArray.count > 1 ? bannerArray.count : 0

        myComment = CommentStruct(imageView: UIImageView(),
                                  badgeImageView: UIImageView(),
                                  id: "",
                                  userID: "",
                                  name: venue.name,
                                  age: "",
                                  gender: "",
                                  country: "",
                                  city: venue.city ?? "",
                                  comment: "",
                                  likes: 0,
                                  isMyComment: false,
                                  isLiked: false,
                                  badgeTitle: "")

        Task {
            do {
                let feedItems = try await WAPData.shared.fetchFeed(locationId: locationID)
                await MainActor.run {
                    for item in feedItems {
                        let imageView = UIImageView()
                        if let avatarURL = item.profile?.avatarURL, !avatarURL.isEmpty {
                            imageView.imageFromServerURL(urlString: avatarURL, tableView: self.commentsTableView)
                        }
                        self.commentsArray.append(CommentStruct(
                            imageView: imageView,
                            badgeImageView: UIImageView(),
                            id: item.id,
                            userID: item.userId,
                            name: item.profile?.displayName ?? "",
                            age: "",
                            gender: "",
                            country: "",
                            city: item.profile?.city ?? "",
                            comment: item.content,
                            likes: 0,
                            isMyComment: item.userId == WAPAuth.currentUserID,
                            isLiked: false,
                            badgeTitle: ""
                        ))
                    }
                    self.commentsTableView.reloadData()
                    self.locationView.isHidden = false
                    self.locationStopLoading()
                }
            } catch {
                await MainActor.run {
                    self.locationStopLoading()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    func getUsers() {
        Task {
            do {
                let presenceRows = try await WAPData.shared.fetchPresence(locationId: locationID)
                await MainActor.run { self.usersSuccess(presenceRows: presenceRows) }
            } catch {
                await MainActor.run {
                    self.usersStopLoading()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    func usersStopLoading() {
        indicator.stopAnimating()
    }

    func usersSuccess(presenceRows: [WAPPresence]) {
        usersArray = []
        for presence in presenceRows {
            let imageView = UIImageView()
            if let avatarURL = presence.profile?.avatarURL, !avatarURL.isEmpty {
                imageView.imageFromServerURL(urlString: avatarURL, tableView: commentsTableView)
            } else {
                imageView.image = UIImage(named: "icon_logo_profile")
            }
            usersArray.append(CustomCell(imageView: imageView,
                                         string1: presence.userId,
                                         string2: presence.profile?.displayName ?? "",
                                         string3: "",
                                         string4: "",
                                         string5: "",
                                         string6: presence.profile?.city ?? "",
                                         string7: "",
                                         isMaster: false))
        }
        commentsTableView.reloadData()
        usersStopLoading()
    }
```

Note: `locationSuccess`/`usersSuccess` changed signatures from `(jsonObject: AnyObject)` to `(venue: WAPVenue)`/`(presenceRows: [WAPPresence])` — this is fine since (per this plan's Global Constraints) nothing outside this file calls them, but grep to double-check before deleting the old versions: `grep -rn "locationSuccess\|usersSuccess" "Wing Me" --include="*.swift"` should show only this file, both before and after the edit.

- [ ] **Step 2: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
cd /Users/sr/wingme-copy
git add "Wing Me/New My Location/NewMyLocationVC.swift"
git commit -m "feat: wire venue/feed/presence loading in NewMyLocationVC to WAPData"
```

---

### Task 2: Wire check-in, check-out, and comment posting

**Files:**
- Modify: `Wing Me/New My Location/NewMyLocationVC.swift` (`wingIn()` no-arg, `wingOff()`, `addComment()`)

**Interfaces:**
- Consumes: `WAPData.shared.checkIn(locationId:)`, `.checkOut(locationId:)`, `.postToFeed(locationId:text:)` (existing, from Phase 1). Does not depend on Task 1's changes — both tasks touch the same file but disjoint methods.

- [ ] **Step 1: Replace `wingIn()`**

Replace:

```swift
    func wingIn() {
        let path = "wing_on.php"
        
        if locationID.contains("Event") {
            return
        }
        var params: NSDictionary {
            if locationID.contains("Event") {
                return [
                    "language": Strings.language,
                    "event_Id": locationID.replacingOccurrences(of: "Event_", with: "")
                ]
            } else {
                return [
                    "language": Strings.language,
                    "location_Id": locationID
                ]
            }
        }
        
        params.request(delegate: self, path: path, stopLoading: wingInStopLoading, requestSuccess: wingInSuccess)
    }
    
    func wingInStopLoading() {
        
    }
    
    func wingInSuccess(jsonObject: AnyObject) {
        
    }
```

with:

```swift
    func wingIn() {
        if locationID.contains("Event") {
            return
        }
        Task {
            do {
                try await WAPData.shared.checkIn(locationId: locationID)
            } catch {
                await MainActor.run {
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }
```

`wingInStopLoading`/`wingInSuccess` had empty bodies in the original (the PHP response was never used) — deleting them along with the PHP call is correct, not a loss of behavior. Before deleting, run `grep -rn "wingInStopLoading\|wingInSuccess" "Wing Me" --include="*.swift"` to confirm no references remain outside this file.

- [ ] **Step 2: Replace `wingOff()`**

Replace:

```swift
    func wingOff() {
        let path = "wing_off.php"
        
        if locationID.contains("Event") {
            return
        }
        var params: NSDictionary {
            if locationID.contains("Event") {
                return [
                    "language": Strings.language,
                    "event_Id": locationID.replacingOccurrences(of: "Event_", with: "")
                ]
            } else {
                return [
                    "language": Strings.language,
                    "location_Id": locationID
                ]
            }
        }
        
        params.request(delegate: self, path: path, stopLoading: wingOffStopLoading, requestSuccess: wingOffSuccess)
    }
    
    func wingOffStopLoading() {
        
    }
    
    func wingOffSuccess(jsonObject: AnyObject) {
        
    }
```

with:

```swift
    func wingOff() {
        if locationID.contains("Event") {
            return
        }
        Task {
            do {
                try await WAPData.shared.checkOut(locationId: locationID)
            } catch {
                await MainActor.run {
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }
```

Same reasoning as Step 1 — confirm no references to `wingOffStopLoading`/`wingOffSuccess` remain outside this file via grep before deleting.

- [ ] **Step 3: Replace the non-event branch of `addComment()`**

Replace:

```swift
    func addComment() {
        let path = "add_comment.php"
        
        var params: NSDictionary {
            if locationID.contains("Event") {
                return [
                    "language": Strings.language,
                    "event_Id": locationID.replacingOccurrences(of: "Event_", with: ""),
                    "comment": commentTextField.getText()
                ]
            } else {
                return [
                    "language": Strings.language,
                    "location_Id": locationID,
                    "comment": commentTextField.getText()
                ]
            }
        }
        
        params.request(delegate: self, path: path, stopLoading: addCommentStopLoading, requestSuccess: addCommentSuccess)
    }
```

with:

```swift
    func addComment() {
        if locationID.contains("Event") {
            let path = "add_comment.php"
            let params: NSDictionary = [
                "language": Strings.language,
                "event_Id": locationID.replacingOccurrences(of: "Event_", with: ""),
                "comment": commentTextField.getText()
            ]
            params.request(delegate: self, path: path, stopLoading: addCommentStopLoading, requestSuccess: addCommentSuccess)
            return
        }
        let text = commentTextField.getText()
        Task {
            do {
                try await WAPData.shared.postToFeed(locationId: locationID, text: text)
                await MainActor.run { self.addCommentSuccess(jsonObject: [:] as AnyObject) }
            } catch {
                await MainActor.run {
                    self.addCommentStopLoading()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }
```

`addCommentStopLoading()` and `addCommentSuccess(jsonObject:)` (both already existing, right below `addComment()` in the file) are unchanged — leave them exactly as they are. `addCommentSuccess`'s `jsonObject` parameter is unused in its body (it only clears the text field and calls `reload()`), so passing an empty `[:]` cast satisfies the existing signature without changing it.

- [ ] **Step 4: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add "Wing Me/New My Location/NewMyLocationVC.swift"
git commit -m "feat: wire check-in/check-out/comment-posting in NewMyLocationVC to WAPData"
```

---

## Verification

1. Both tasks committed, `xcodebuild ... build` succeeds at HEAD.
2. Manual: check into a non-event venue — feed and "who's here" list populate from Supabase data (or render empty if the venue has none, without crashing). Post a comment — it appears after `reload()` re-fetches. Check out — no crash; verify in Supabase Table Editor that the `location_checkins` row for that user/venue got `checked_out_at` set.
3. Manual: check into an event (`locationID` containing `"Event"`, if reachable in the current UI) — confirm it still uses the old PHP path unchanged (no regression from this plan).
4. `grep -n "\.php" "Wing Me/New My Location/NewMyLocationVC.swift"` still shows `get_event.php`, `add_comment.php` (event branch only), `add_like.php`, `delete_comment_likes.php`, `delete_comment.php`, `assign_badge.php`/`master_assign_badge.php`, `remove_badge.php`/`master_remove_badge.php` — confirms only the five intended call sites (`get_location.php`, `get_users.php`, `wing_on.php`, `wing_off.php`, `add_comment.php`'s non-event branch) were removed, nothing else touched.

## Known Deferred
- Likes/reactions, badges, replies, in-comment chat — unchanged, still PHP-backed.
- Event-specific loading/check-in/check-out/commenting (`get_event.php`, the `"Event_"`-prefixed `locationID` convention) — unchanged, still PHP-backed. A future phase should decide whether events should be reconciled onto the same `locations`/`WAPVenue` model (they already share the table via `WAPVenue.isEvent`) or kept as a distinct concept.
- Multi-banner carousel — collapsed to a single banner image, since `WAPVenue.bannerImage` only has one.
- Venue welcome/default message (`myComment.comment`) — no backing field, renders empty.
