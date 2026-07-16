# Beta Phase 5 — Locations Tab + Rewards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire `LocationsVC` (Tab 1) to Supabase `fetchVenues()`, replacing the PHP backend and removing the legacy categories UI; then add a new `RewardsVC` accessible from the venue screen showing real rewards from `fetchRewards(locationId:)`.

**Architecture:** `LocationsVC` simplifies from a category-filtered multi-section layout to a flat venue list + Google Maps pins — categories are not in `WAPVenue` and removed per YAGNI. The `checkLocation()` geofence check is rewritten to read from `[WAPVenue]` instead of `[CustomCell]`. The delegate bridge (`delegate.wingIn(customCell:)`) is preserved by constructing `CustomCell(string1: venue.id, string2: venue.name)`. `RewardsVC` is a new programmatic VC presented from `NewMyLocationVC`.

**Tech Stack:** Swift/UIKit, WAPData.shared, WAPAuth.currentUserID, Google Maps SDK (existing), CoreLocation (existing), no new dependencies.

## Global Constraints

- Backend: Supabase only — no `URLSession` calls to `thewapp.app` or any PHP endpoint
- Auth: user check via `WAPAuth.currentUserID != nil` — never `UserDefaults.getString(key: "Token")`
- `CustomCell(string1:string2:)` bridge call in `checkLocation()` must be preserved: `string1 = venue.id`, `string2 = venue.name` — `NewMyLocationVC.wingIn(customCell:)` reads `customCell.string1` as the Supabase UUID
- `WAPVenue`: `id: String`, `name: String`, `address: String?`, `city: String?`, `lat: Double?`, `lng: Double?`, `geofenceRadiusMeters: Int?`, `isEvent: Bool?`, `eventDate: String?`, `bannerImage: String?`
- `WAPReward`: `id: String`, `locationId: String`, `name: String`, `iconType: String?`, `dealText: String?`, `instructions: String?`, `isActive: Bool`, `displayOrder: Int`, `featureName: String?`
- No XCTest target exists — verify via Xcode build (Cmd+B → BUILD SUCCEEDED) only
- YAGNI: remove category collection view entirely; do not add filter UI, pagination, or banner carousel

---

### Task 1: LocationsVC — Replace PHP + CustomCell with Supabase WAPVenue

**Files:**
- Modify: `The W App/Locations/LocationsVC.swift`
- Modify: `The W App/Locations/LocationCell.swift`

**Interfaces:**
- Consumes: `WAPData.shared.fetchVenues() async throws -> [WAPVenue]`
- Consumes: `WAPAuth.currentUserID: String?`
- Produces (unchanged): `checkLocation()` — reads from `venues: [WAPVenue]`, calls `delegate.wingIn(CustomCell(string1:string2:))`

- [ ] **Step 1: Read the existing file before editing**

  ```bash
  wc -l "The W App/Locations/LocationsVC.swift"
  grep -n "func \|var \|@IBOutlet\|@IBAction" "The W App/Locations/LocationsVC.swift" | head -60
  cat "The W App/Locations/LocationCell.swift"
  ```

- [ ] **Step 2: Remove category properties and UI**

  Delete these properties:
  ```swift
  var categoriesArray: [CustomCell] = []
  var visibleCategoriesArray: [CustomCell] = []
  var lastCategory = Int()
  var lastVisibleCategory = Int()
  ```

  In `viewDidLoad`, hide the category collection view (keep IBOutlet to avoid storyboard crash):
  ```swift
  collectionView.isHidden = true
  ```

  Delete these methods entirely (they drive the category collection view):
  - All `UICollectionViewDataSource` / `UICollectionViewDelegateFlowLayout` methods
  - Any `@IBAction` that switches the selected category

- [ ] **Step 3: Replace `locationsArray` + `searchArray` with `venues` + `filteredVenues`**

  ```swift
  var venues: [WAPVenue] = []
  var filteredVenues: [WAPVenue] = []
  ```

- [ ] **Step 4: Replace `request()` and remove PHP callbacks**

  Delete: `stopLoading()`, `requestSuccess(jsonObject:)`, `getLocation(dictionary:tableView:)`.

  Replace `request()`:
  ```swift
  @objc func request() {
      guard WAPAuth.currentUserID != nil else { return }
      Task { [weak self] in
          guard let self else { return }
          do {
              let fetched = try await WAPData.shared.fetchVenues()
              await MainActor.run {
                  self.venues = fetched
                  self.filteredVenues = fetched
                  self.tableView.reloadData()
                  self.addMapMarkers()
                  self.indicator.stopAnimating()
              }
          } catch {
              await MainActor.run {
                  self.indicator.stopAnimating()
                  AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
              }
          }
      }
  }
  ```

- [ ] **Step 5: Rewrite UITableView data source to use `filteredVenues`**

  ```swift
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      filteredVenues.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      guard let cell = tableView.dequeueReusableCell(withReuseIdentifier: "LocationCell", for: indexPath) as? LocationCell else {
          return UITableViewCell()
      }
      cell.updateCell(venue: filteredVenues[indexPath.row])
      return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      let venue = filteredVenues[indexPath.row]
      openSingleLocation(customCell: CustomCell(string1: venue.id, string2: venue.name))
  }
  ```

- [ ] **Step 6: Add `addMapMarkers()` using `venues`**

  Find the existing method that places GMSMarkers and replace its internals:
  ```swift
  private func addMapMarkers() {
      mapView.clear()
      for venue in venues {
          guard let lat = venue.lat, let lng = venue.lng else { continue }
          let marker = GMSMarker()
          marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lng)
          marker.title = venue.name
          marker.snippet = venue.address ?? ""
          marker.map = mapView
      }
  }
  ```

- [ ] **Step 7: Rewrite search filter**

  ```swift
  @objc func textFieldDidChange(_ textField: UITextField) {
      let query = (textField.text ?? "").lowercased()
      filteredVenues = query.isEmpty ? venues : venues.filter {
          $0.name.lowercased().contains(query) ||
          ($0.address?.lowercased().contains(query) ?? false)
      }
      tableView.reloadData()
  }
  ```

- [ ] **Step 8: Rewrite `checkLocation()` to use `venues: [WAPVenue]`**

  ```swift
  func checkLocation() {
      guard WAPAuth.currentUserID != nil else { return }
      let locationID = UserDefaults.getString(key: "LocationID")
      if locationID.contains("Event") { return }
      guard let _ = accurateLocation else { return }

      let userCoord = CLLocation(latitude: latitude, longitude: longitude)
      let accuracy = sqrt(pow(accurateLocation!.horizontalAccuracy, 2) +
                          pow(accurateLocation!.verticalAccuracy, 2))

      var nearby: [WAPVenue] = []
      for venue in venues {
          guard let lat = venue.lat, let lng = venue.lng else { continue }
          let radius = Double(venue.geofenceRadiusMeters ?? 50)
          let dist = userCoord.distance(from: CLLocation(latitude: lat, longitude: lng))
          if dist <= radius + (accuracy < 20 ? 20 : accuracy) {
              nearby.append(venue)
          }
      }

      if appDelegate.inLocation {
          if nearby.isEmpty {
              appDelegate.inLocation = false
              delegate.hideLocation()
              ["LocationID", "LocationName", "LastLocationAlert", "LastLocationNotification"]
                  .forEach { UserDefaults.standard.removeObject(forKey: $0) }
          } else {
              let lastID = UserDefaults.getString(key: "LastLocationAlert")
              if !nearby.contains(where: { $0.id == lastID }) {
                  delegate.hideLocation()
                  if appDelegate.isBackground { sendNotification(venues: nearby) }
                  showVenueAlert(venues: nearby)
                  UserDefaults.standard.removeObject(forKey: "LocationID")
                  UserDefaults.standard.removeObject(forKey: "LocationName")
              }
          }
      } else {
          if !nearby.isEmpty {
              appDelegate.inLocation = true
              let storedID = UserDefaults.getString(key: "LocationID")
              if nearby.contains(where: { $0.id == storedID }) {
                  let name = UserDefaults.getString(key: "LocationName")
                  delegate.wingIn(CustomCell(string1: storedID, string2: name))
              } else {
                  delegate.hideLocation()
                  if appDelegate.isBackground { sendNotification(venues: nearby) }
                  showVenueAlert(venues: nearby)
                  UserDefaults.standard.removeObject(forKey: "LocationID")
                  UserDefaults.standard.removeObject(forKey: "LocationName")
              }
          } else {
              ["LocationID", "LocationName", "LastLocationAlert", "LastLocationNotification"]
                  .forEach { UserDefaults.standard.removeObject(forKey: $0) }
          }
      }
  }
  ```

- [ ] **Step 9: Update `sendNotification` and `showAlert` to use `[WAPVenue]`**

  Read the existing `sendNotification` and `showAlert` implementations, then replace the `[CustomCell]` parameter with `[WAPVenue]` and update all field accesses from `customCell.string2` → `venue.name`, `customCell.string1` → `venue.id`.

  Rename old `showAlert` to `showVenueAlert` to avoid conflict with any UIKit naming:
  ```swift
  func sendNotification(venues: [WAPVenue]) { ... }
  func showVenueAlert(venues: [WAPVenue]) { ... }
  ```

- [ ] **Step 10: Add `updateCell(venue:)` to LocationCell**

  Read `The W App/Locations/LocationCell.swift`, then add:
  ```swift
  func updateCell(venue: WAPVenue) {
      // Set name label using venue.name
      // Set address/subtitle label using venue.address ?? venue.city ?? ""
      // Keep any existing banner image loading if outlet exists
  }
  ```

  Read the file first to see actual outlet names before writing.

- [ ] **Step 11: Build and commit**

  Cmd+B → BUILD SUCCEEDED.

  ```bash
  git add "The W App/Locations/LocationsVC.swift" "The W App/Locations/LocationCell.swift"
  git commit -m "feat: wire LocationsVC to Supabase fetchVenues, remove PHP categories"
  ```

---

### Task 2: RewardsVC — New programmatic rewards screen per venue

**Files:**
- Create: `The W App/New My Location/RewardsVC.swift`
- Modify: `The W App/New My Location/NewMyLocationVC.swift`

**Interfaces:**
- Consumes: `WAPData.shared.fetchRewards(locationId: String) async throws -> [WAPReward]`
- `RewardsVC(locationId: String)` — init with the current venue UUID

- [ ] **Step 1: Read NewMyLocationVC to find the history button IBAction**

  ```bash
  grep -n "@IBAction\|func history\|func attendee\|locationID\b" "The W App/New My Location/NewMyLocationVC.swift" | head -20
  ```

- [ ] **Step 2: Create `The W App/New My Location/RewardsVC.swift`**

  ```swift
  import UIKit

  class RewardsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

      private let locationId: String
      private let tableView = UITableView(frame: .zero, style: .plain)
      private var rewards: [WAPReward] = []

      init(locationId: String) {
          self.locationId = locationId
          super.init(nibName: nil, bundle: nil)
      }

      required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

      override func viewDidLoad() {
          super.viewDidLoad()
          view.backgroundColor = .systemBackground
          setupHeader()
          setupTableView()
          loadRewards()
      }

      private func setupHeader() {
          let close = UIButton(type: .system)
          close.setTitle("✕", for: .normal)
          close.titleLabel?.font = .systemFont(ofSize: 20)
          close.translatesAutoresizingMaskIntoConstraints = false
          close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

          let title = UILabel()
          title.text = "Rewards"
          title.font = .boldSystemFont(ofSize: 18)
          title.translatesAutoresizingMaskIntoConstraints = false

          view.addSubview(close)
          view.addSubview(title)
          NSLayoutConstraint.activate([
              close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
              close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
              title.centerYAnchor.constraint(equalTo: close.centerYAnchor),
              title.centerXAnchor.constraint(equalTo: view.centerXAnchor),
          ])
      }

      private func setupTableView() {
          tableView.translatesAutoresizingMaskIntoConstraints = false
          tableView.dataSource = self
          tableView.delegate = self
          tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RewardCell")
          tableView.rowHeight = UITableView.automaticDimension
          tableView.estimatedRowHeight = 72
          view.addSubview(tableView)
          NSLayoutConstraint.activate([
              tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
              tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
              tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
              tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
          ])
      }

      private func loadRewards() {
          Task { [weak self] in
              guard let self else { return }
              do {
                  let fetched = try await WAPData.shared.fetchRewards(locationId: locationId)
                  await MainActor.run {
                      self.rewards = fetched
                      self.tableView.reloadData()
                  }
              } catch {
                  await MainActor.run {
                      AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                  }
              }
          }
      }

      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          rewards.isEmpty ? 1 : rewards.count
      }

      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          let cell = tableView.dequeueReusableCell(withIdentifier: "RewardCell", for: indexPath)
          var config = cell.defaultContentConfiguration()
          if rewards.isEmpty {
              config.text = "No rewards available at this venue."
              config.textProperties.color = .secondaryLabel
              cell.selectionStyle = .none
          } else {
              let r = rewards[indexPath.row]
              config.text = r.name
              config.secondaryText = r.dealText
              config.image = UIImage(systemName: iconSystemName(for: r.iconType))
          }
          cell.contentConfiguration = config
          return cell
      }

      func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
          tableView.deselectRow(at: indexPath, animated: true)
          guard !rewards.isEmpty else { return }
          let r = rewards[indexPath.row]
          let msg = r.instructions ?? r.dealText ?? "No details available."
          let alert = UIAlertController(title: r.name, message: msg, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .default))
          present(alert, animated: true)
      }

      private func iconSystemName(for iconType: String?) -> String {
          switch iconType {
          case "drink":   return "cup.and.saucer.fill"
          case "food":    return "fork.knife"
          case "ticket":  return "ticket.fill"
          case "percent": return "percent"
          case "vip":     return "star.fill"
          case "valet":   return "car.fill"
          default:        return "gift.fill"
          }
      }

      @objc private func closeTapped() { dismiss(animated: true) }
  }
  ```

- [ ] **Step 3: Register RewardsVC.swift in Xcode project**

  ```bash
  ruby -e "
  require 'xcodeproj'
  project = Xcodeproj::Project.open('The W App.xcodeproj')
  target = project.targets.find { |t| t.name == 'The W App' }
  group = project.main_group.find_subpath('The W App/New My Location', true)
  file_ref = group.new_reference('RewardsVC.swift')
  file_ref.last_known_file_type = 'sourcecode.swift'
  target.source_build_phase.add_file_reference(file_ref)
  project.save
  puts 'RewardsVC.swift added'
  "
  ```

- [ ] **Step 4: Add rewards entry point to NewMyLocationVC**

  Read `viewDidLoad` in `NewMyLocationVC.swift`, then add a programmatic trophy button near the existing history button. Find where the history button is wired (grep for `@IBAction func` and `history` or `AttendeeHistory`) and add:

  ```swift
  @objc private func rewardsTapped() {
      guard !locationID.isEmpty else { return }
      let vc = RewardsVC(locationId: locationID)
      vc.modalPresentationStyle = .pageSheet
      present(vc, animated: true)
  }
  ```

  If there is an existing `@IBAction func rewards` slot wired in the storyboard, use that. Otherwise add a programmatic UIButton with `UIImage(systemName: "trophy.fill")` and tint `Colors.blue`, positioned near the history button in the header area.

- [ ] **Step 5: Build and commit**

  Cmd+B → BUILD SUCCEEDED.

  ```bash
  git add "The W App/New My Location/RewardsVC.swift" \
          "The W App/New My Location/NewMyLocationVC.swift" \
          "The W App.xcodeproj/project.pbxproj"
  git commit -m "feat: add RewardsVC and wire rewards entry point in NewMyLocationVC"
  ```

---
