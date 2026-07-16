# WAP Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebrand The W App to The W App, replace the PHP/thewapp.app backend with Supabase, and establish auth — producing a building, launchable app shell with working sign-in.

**Architecture:** Fork thewapp-copy in-place; strip dating logic; wire Supabase Swift SDK (SPM) for auth + database + storage; keep Firebase for push notifications only; replace UserDefaults token with Keychain.

**Tech Stack:** Swift/UIKit, CocoaPods (Firebase, GoogleMaps, GooglePlaces, FBSDKLoginKit), Supabase Swift SDK 2.x (SPM), XCTest

## Global Constraints

- iOS deployment target: 15.6 (unchanged)
- Bundle ID change: `com.vastlb.Wing-Me` → `com.thewapp.wap`
- Target name: `The W App` → `The W App`
- Supabase Swift SDK added via Swift Package Manager (no CocoaPods pod exists)
- Firebase kept for push notifications only — Firebase/Auth removed
- All `thewapp.app` URLs removed — no calls to old backend ever made
- No dating fields: remove relationship status, "looking for" enums, all related UI
- Ponytail rule: reuse existing The W App code before writing anything new

---

### Task 1: Rename Xcode Target and Update Bundle ID

**Files:**
- Modify: `The W App.xcodeproj/project.pbxproj` (via Ruby xcodeproj gem — CLI only)
- Modify: `The W App/Info.plist`
- Modify: `Podfile`
- Create: `scripts/rebrand_target.rb`

**Interfaces:**
- Produces: app module name `TheWApp`, bundle ID `com.thewapp.wap`, Podfile target `The W App`

- [ ] **Step 1: Create scripts directory**

  ```bash
  mkdir -p /Users/sr/thewapp-copy/scripts
  ```

- [ ] **Step 2: Create rebrand_target.rb**

  Create `scripts/rebrand_target.rb`:

  ```ruby
  require 'xcodeproj'

  PROJECT_PATH = File.join(__dir__, '..', 'The W App.xcodeproj')
  OLD_NAME = 'The W App'
  NEW_NAME = 'The W App'
  NEW_BUNDLE_ID = 'com.thewapp.wap'

  project = Xcodeproj::Project.open(PROJECT_PATH)

  project.targets.each do |target|
    next unless target.name == OLD_NAME
    target.name = NEW_NAME
    target.build_configurations.each do |config|
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = NEW_BUNDLE_ID
      config.build_settings['PRODUCT_NAME'] = NEW_NAME
    end
    puts "Renamed target '#{OLD_NAME}' → '#{NEW_NAME}'"
    puts "Bundle ID set to '#{NEW_BUNDLE_ID}'"
  end

  project.save
  puts "Saved #{PROJECT_PATH}"
  ```

- [ ] **Step 3: Run the rebrand script**

  ```bash
  cd /Users/sr/thewapp-copy
  ruby scripts/rebrand_target.rb
  ```

  Expected output:
  ```
  Renamed target 'The W App' → 'The W App'
  Bundle ID set to 'com.thewapp.wap'
  Saved .../The W App.xcodeproj
  ```

- [ ] **Step 4: Update Info.plist display name**

  ```bash
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'The W App'" "/Users/sr/thewapp-copy/The W App/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleName 'TheWApp'" "/Users/sr/thewapp-copy/The W App/Info.plist"
  ```

  Expected: no output (silent success).

- [ ] **Step 5: Update Podfile**

  Replace entire `Podfile` content:

  ```ruby
  platform :ios, '15.6'

  target 'The W App' do
    use_frameworks!

    pod 'Firebase/Core'
    pod 'Firebase/Messaging'
    pod 'GoogleMaps'
    pod 'Google-Maps-iOS-Utils'
    pod 'GooglePlaces'
    pod 'FBSDKLoginKit'
  end
  ```

  Note: `Firebase/Auth` removed — Supabase handles auth. `GooglePlaces` added for Add Location search.

- [ ] **Step 6: Run pod install**

  ```bash
  cd /Users/sr/thewapp-copy && pod install 2>&1 | tail -5
  ```

  Expected: `Pod installation complete!`

- [ ] **Step 7: Verify project.pbxproj contains new values**

  ```bash
  grep -c "com.thewapp.wap" "/Users/sr/thewapp-copy/The W App.xcodeproj/project.pbxproj"
  grep -c "The W App" "/Users/sr/thewapp-copy/The W App.xcodeproj/project.pbxproj"
  ```

  Expected: both return `2` (one per build configuration).

- [ ] **Step 8: Commit**

  ```bash
  cd /Users/sr/thewapp-copy
  git add -A
  git commit -m "rebrand: rename target to The W App, update bundle ID, add GooglePlaces"
  ```

---

### Task 2: Add Supabase Swift SDK via SPM

**Files:**
- Modify: `The W App.xcodeproj/project.pbxproj` (via Ruby xcodeproj gem — CLI only)
- Create: `scripts/add_supabase_spm.rb`
- Create: `The W App/Classes/WAPSupabase.swift`
- Create: `The W AppTests/WAPSupabaseTests.swift`

**Interfaces:**
- Produces: `WAPSupabase.shared.client: SupabaseClient` — singleton accessible throughout the app
- Depends on: Task 1 having renamed the target to `The W App`

- [ ] **Step 1: Create add_supabase_spm.rb**

  Create `scripts/add_supabase_spm.rb`:

  ```ruby
  require 'xcodeproj'

  PROJECT_PATH = File.join(__dir__, '..', 'The W App.xcodeproj')
  TARGET_NAME  = 'The W App'
  REPO_URL     = 'https://github.com/supabase/supabase-swift'
  MIN_VERSION  = '2.0.0'
  PRODUCT_NAME = 'Supabase'

  project = Xcodeproj::Project.open(PROJECT_PATH)

  # Check if already added
  existing = project.root_object.package_references.find do |ref|
    ref.respond_to?(:repository_url) && ref.repository_url == REPO_URL
  end
  if existing
    puts "Supabase SPM package already present — skipping"
    exit 0
  end

  # Add remote package reference
  pkg_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  pkg_ref.repository_url = REPO_URL
  pkg_ref.requirement = {
    'kind'           => 'upToNextMajorVersion',
    'minimumVersion' => MIN_VERSION
  }
  project.root_object.package_references << pkg_ref

  # Add product dependency to target
  target = project.targets.find { |t| t.name == TARGET_NAME }
  abort("Target '#{TARGET_NAME}' not found — run rebrand_target.rb first") unless target

  dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dep.package = pkg_ref
  dep.product_name = PRODUCT_NAME
  target.package_product_dependencies << dep

  project.save
  puts "Added Supabase SPM package to target '#{TARGET_NAME}'"
  ```

- [ ] **Step 2: Run the SPM script**

  ```bash
  cd /Users/sr/thewapp-copy
  ruby scripts/add_supabase_spm.rb
  ```

  Expected output:
  ```
  Added Supabase SPM package to target 'The W App'
  ```

- [ ] **Step 3: Verify package reference in project.pbxproj**

  ```bash
  grep -c "supabase-swift" "/Users/sr/thewapp-copy/The W App.xcodeproj/project.pbxproj"
  grep -c "XCRemoteSwiftPackageReference" "/Users/sr/thewapp-copy/The W App.xcodeproj/project.pbxproj"
  ```

  Expected: both return at least `1`.

- [ ] **Step 4: Create WAPSupabase.swift**

  Create `The W App/Classes/WAPSupabase.swift`:

  ```swift
  import Foundation
  import Supabase

  final class WAPSupabase {
      static let shared = WAPSupabase()

      let client: SupabaseClient

      private init() {
          let url = URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "")!
          let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
          client = SupabaseClient(supabaseURL: url, supabaseKey: key)
      }
  }
  ```

  Note: `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set via Xcode Edit Scheme → Run → Environment Variables. Never commit real keys to git.

- [ ] **Step 5: Create WAPSupabaseTests.swift**

  Create `The W AppTests/WAPSupabaseTests.swift`:

  ```swift
  import XCTest
  @testable import TheWApp

  final class WAPSupabaseTests: XCTestCase {
      func testSharedClientExists() {
          XCTAssertNotNil(WAPSupabase.shared.client)
      }
  }
  ```

  Note: `@testable import TheWApp` must match the Product Module Name (found in Build Settings → Product Module Name). If the target was renamed via xcodeproj gem, the module name may still be `TheWApp` — check and update accordingly.

- [ ] **Step 6: Commit**

  ```bash
  cd /Users/sr/thewapp-copy
  git add "The W App.xcodeproj/project.pbxproj" scripts/add_supabase_spm.rb \
    "The W App/Classes/WAPSupabase.swift" "The W AppTests/WAPSupabaseTests.swift"
  git commit -m "feat: add Supabase Swift SDK via SPM, create WAPSupabase singleton"
  ```

---

### Task 3: Keychain Token Storage

**Files:**
- Create: `The W App/Classes/KeychainHelper.swift`
- Create: `The W AppTests/KeychainHelperTests.swift`

**Interfaces:**
- Produces: `KeychainHelper.save(key:value:)`, `KeychainHelper.load(key:) -> String?`, `KeychainHelper.delete(key:)`
- Produces: `KeychainHelper.Keys.authToken = "wap_auth_token"`

- [ ] **Step 1: Write failing tests**

  Create `The W AppTests/KeychainHelperTests.swift`:

  ```swift
  import XCTest
  @testable import TheWApp

  final class KeychainHelperTests: XCTestCase {
      override func tearDown() {
          KeychainHelper.delete(key: "test_key")
          super.tearDown()
      }

      func testSaveAndLoad() {
          KeychainHelper.save(key: "test_key", value: "test_value")
          XCTAssertEqual(KeychainHelper.load(key: "test_key"), "test_value")
      }

      func testOverwrite() {
          KeychainHelper.save(key: "test_key", value: "first")
          KeychainHelper.save(key: "test_key", value: "second")
          XCTAssertEqual(KeychainHelper.load(key: "test_key"), "second")
      }

      func testDelete() {
          KeychainHelper.save(key: "test_key", value: "value")
          KeychainHelper.delete(key: "test_key")
          XCTAssertNil(KeychainHelper.load(key: "test_key"))
      }

      func testMissingKeyReturnsNil() {
          XCTAssertNil(KeychainHelper.load(key: "nonexistent_xyz"))
      }
  }
  ```

- [ ] **Step 2: Run tests — expect fail**

  Cmd+U. Expected: FAIL — `KeychainHelper` not found.

- [ ] **Step 3: Create KeychainHelper.swift**

  Create `The W App/Classes/KeychainHelper.swift`:

  ```swift
  import Security
  import Foundation

  enum KeychainHelper {
      enum Keys {
          static let authToken = "wap_auth_token"
      }

      @discardableResult
      static func save(key: String, value: String) -> Bool {
          guard let data = value.data(using: .utf8) else { return false }
          let query: [CFString: Any] = [
              kSecClass: kSecClassGenericPassword,
              kSecAttrAccount: key,
              kSecValueData: data
          ]
          SecItemDelete(query as CFDictionary)
          return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
      }

      static func load(key: String) -> String? {
          let query: [CFString: Any] = [
              kSecClass: kSecClassGenericPassword,
              kSecAttrAccount: key,
              kSecReturnData: true,
              kSecMatchLimit: kSecMatchLimitOne
          ]
          var result: AnyObject?
          guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
                let data = result as? Data else { return nil }
          return String(data: data, encoding: .utf8)
      }

      @discardableResult
      static func delete(key: String) -> Bool {
          let query: [CFString: Any] = [
              kSecClass: kSecClassGenericPassword,
              kSecAttrAccount: key
          ]
          return SecItemDelete(query as CFDictionary) == errSecSuccess
      }
  }
  ```

- [ ] **Step 4: Run tests — expect pass**

  Cmd+U. Expected: all 4 KeychainHelperTests PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add "The W App/Classes/KeychainHelper.swift" "The W AppTests/KeychainHelperTests.swift"
  git commit -m "feat: Keychain helper for auth token storage"
  ```

---

### Task 4: Update Constants and Strings

**Files:**
- Modify: `The W App/Classes/Constants.swift`
- Modify: `The W App/Classes/Strings.swift`

**Interfaces:**
- Produces: `Strings.checkIn`, `Strings.checkOut`, `Strings.whoIsHere`, `Strings.alertCheckIn` replacing old The W App equivalents

- [ ] **Step 1: Replace Constants.swift**

  ```swift
  import UIKit

  class Constants {
      static let appURL = "https://thewapp.com/"
      static let deleteAccountURL = "https://thewapp.com/delete_account"
      static var savedImages = [String: UIImage]()

      // UserDefaults keys (auth token lives in Keychain, not here)
      static let locationID = "LocationID"
      static let locationName = "LocationName"
      static let setup = "Setup"
      static let lastDate = "LastDate"
      static let lastLocationAlert = "LastLocationAlert"
      static let lastLocationNotification = "LastLocationNotification"

      static let countryCodes: [String: String] = [
          "Afghanistan": "+93", "Albania": "+355", "Algeria": "+213",
          "Argentina": "+54", "Australia": "+61", "Austria": "+43",
          "Bahrain": "+973", "Bangladesh": "+880", "Belgium": "+32",
          "Brazil": "+55", "Canada": "+1", "Chile": "+56",
          "China": "+86", "Colombia": "+57", "Croatia": "+385",
          "Czech Republic": "+420", "Denmark": "+45", "Egypt": "+20",
          "Finland": "+358", "France": "+33", "Germany": "+49",
          "Ghana": "+233", "Greece": "+30", "Hong Kong": "+852",
          "Hungary": "+36", "India": "+91", "Indonesia": "+62",
          "Iran": "+98", "Iraq": "+964", "Ireland": "+353",
          "Israel": "+972", "Italy": "+39", "Japan": "+81",
          "Jordan": "+962", "Kenya": "+254", "Kuwait": "+965",
          "Lebanon": "+961", "Libya": "+218", "Malaysia": "+60",
          "Mexico": "+52", "Morocco": "+212", "Netherlands": "+31",
          "New Zealand": "+64", "Nigeria": "+234", "Norway": "+47",
          "Oman": "+968", "Pakistan": "+92", "Palestine": "+970",
          "Peru": "+51", "Philippines": "+63", "Poland": "+48",
          "Portugal": "+351", "Qatar": "+974", "Romania": "+40",
          "Russia": "+7", "Saudi Arabia": "+966", "Singapore": "+65",
          "South Africa": "+27", "South Korea": "+82", "Spain": "+34",
          "Sri Lanka": "+94", "Sudan": "+249", "Sweden": "+46",
          "Switzerland": "+41", "Syria": "+963", "Taiwan": "+886",
          "Thailand": "+66", "Tunisia": "+216", "Turkey": "+90",
          "UAE": "+971", "Uganda": "+256", "UK": "+44",
          "Ukraine": "+380", "USA": "+1", "Venezuela": "+58",
          "Vietnam": "+84", "Yemen": "+967", "Zimbabwe": "+263"
      ]
  }
  ```

- [ ] **Step 2: Replace Strings.swift**

  ```swift
  import UIKit

  class Strings {
      static let language = NSLocalizedString("en", comment: "")

      static let alertError = NSLocalizedString("Error!", comment: "")
      static let alertWarning = NSLocalizedString("Warning!", comment: "")
      static let alertSuccess = NSLocalizedString("Success!", comment: "")
      static let alertOK = NSLocalizedString("OK", comment: "")
      static let alertYes = NSLocalizedString("Yes", comment: "")
      static let alertNo = NSLocalizedString("No", comment: "")
      static let alertCancel = NSLocalizedString("Cancel", comment: "")
      static let alertSetup = NSLocalizedString("Setup Profile", comment: "")
      static let alertSetupNow = NSLocalizedString("Setup Now", comment: "")
      static let alertLater = NSLocalizedString("Later", comment: "")
      static let alertNever = NSLocalizedString("Never", comment: "")

      static let alertConnection = NSLocalizedString("An error has occurred! Please check your internet connection or try again later", comment: "")
      static let alertEmpty = NSLocalizedString("All fields must be filled to proceed", comment: "")
      static let alertBoth = NSLocalizedString("Both passwords must be similar", comment: "")
      static let alertVerification = NSLocalizedString("The verification code is not correct", comment: "")
      static let alertTerms = NSLocalizedString("You must agree to the Terms & Conditions", comment: "")
      static let alertCheckIn = NSLocalizedString("You need to check in first", comment: "")

      static let alertLogout = NSLocalizedString("Are you sure you want to logout?", comment: "")
      static let alertBlock = NSLocalizedString("Are you sure you want to block this user?", comment: "")
      static let alertReport = NSLocalizedString("Are you sure you want to report this user?", comment: "")
      static let alertUnblock = NSLocalizedString("Are you sure you want to unblock this user?", comment: "")
      static let alertDelete = NSLocalizedString("Are you sure you want to delete this conversation?", comment: "")
      static let alertSetupProfile = NSLocalizedString("Your profile is incomplete, do you want to continue setting up your profile?", comment: "")
      static let alertSaveProfile = NSLocalizedString("Do you want to save your changed info?", comment: "")
      static let alertDeleteGroup = NSLocalizedString("Are you sure you want to delete this group?", comment: "")
      static let alertLeaveGroup = NSLocalizedString("Are you sure you want to leave this group?", comment: "")

      static let alertPasswordChanged = NSLocalizedString("Your password has been changed", comment: "")
      static let alertMessageSent = NSLocalizedString("Your message has been sent", comment: "")
      static let alertInfoEdited = NSLocalizedString("Your info has been edited", comment: "")
      static let alertReported = NSLocalizedString("This user has been reported", comment: "")
      static let alertPasswordReset = NSLocalizedString("Your password has been reset", comment: "")
      static let alertLocationInfo = NSLocalizedString("Your location info has been edited", comment: "")
      static let alertImageAdded = NSLocalizedString("Your image has been added", comment: "")
      static let alertCheckedIn = NSLocalizedString("You are now checked in", comment: "")
      static let alertCheckedOut = NSLocalizedString("You have checked out", comment: "")

      static let optionTitle = NSLocalizedString("Select an Option", comment: "")
      static let optionDetails = NSLocalizedString("Set picture via:", comment: "")
      static let optionCamera = NSLocalizedString("Camera", comment: "")
      static let optionGallery = NSLocalizedString("Gallery", comment: "")
      static let optionMyFiles = NSLocalizedString("My Files", comment: "")
      static let optionCancel = NSLocalizedString("Cancel", comment: "")

      static let logout = NSLocalizedString("Logout", comment: "")
      static let today = NSLocalizedString("Today", comment: "")
      static let yesterday = NSLocalizedString("Yesterday", comment: "")
      static let about = NSLocalizedString("About us", comment: "")
      static let terms = NSLocalizedString("Terms & Conditions", comment: "")
      static let privacy = NSLocalizedString("Privacy Policy", comment: "")
      static let viewProfile = NSLocalizedString("View Profile", comment: "")
      static let block = NSLocalizedString("Block", comment: "")
      static let report = NSLocalizedString("Report", comment: "")
      static let unblock = NSLocalizedString("Unblock", comment: "")
      static let delete = NSLocalizedString("Delete", comment: "")
      static let message = NSLocalizedString("Message", comment: "")
      static let checkIn = NSLocalizedString("Check In", comment: "")
      static let checkOut = NSLocalizedString("Check Out", comment: "")
      static let whoIsHere = NSLocalizedString("WHO'S HERE", comment: "")
      static let whenAndWhere = NSLocalizedString("When and Where", comment: "")
      static let maybeLater = NSLocalizedString("Maybe later", comment: "")
      static let discardChanges = NSLocalizedString("Discard Changes", comment: "")
      static let saveChanges = NSLocalizedString("Save Changes", comment: "")
      static let shareWhatever = NSLocalizedString("Share whatever where ever...", comment: "")
      static let unlockWhoIsNear = NSLocalizedString("Unlock who's near", comment: "")
      static let finishSetup = NSLocalizedString("Finish setting up your profile to unlock who's nearby.", comment: "")
  }
  ```

- [ ] **Step 3: Fix broken references**

  ```bash
  grep -rn "wingOut\|alertWingout\|alertBadgeAdded\|alertEventCreated\|alertEventEdited" \
    /Users/sr/thewapp-copy/ --include="*.swift" 2>/dev/null
  ```

  For each hit: replace `Strings.wingOut` → `Strings.checkIn`, `Strings.alertWingout` → `Strings.alertCheckIn`. Remove any reference to removed strings entirely if the caller is dating-specific code being deleted in Task 7.

- [ ] **Step 4: Build**

  Cmd+B → Build Succeeded.

- [ ] **Step 5: Commit**

  ```bash
  git add "The W App/Classes/Constants.swift" "The W App/Classes/Strings.swift"
  git commit -m "rebrand: update Constants and Strings, remove The W App references"
  ```

---

### Task 5: Supabase Database Schema

**Files:**
- Create: `database/migrations/001_initial_schema.sql`
- Create: `database/migrations/002_seed_data.sql`

**Interfaces:**
- Produces: all WAP tables in Supabase; Realtime enabled on `location_checkins`, `feed_posts`, `peek_invites`

- [ ] **Step 1: Create migrations directory**

  ```bash
  mkdir -p /Users/sr/thewapp-copy/database/migrations
  ```

- [ ] **Step 2: Create 001_initial_schema.sql**

  Create `database/migrations/001_initial_schema.sql`:

  ```sql
  create extension if not exists "uuid-ossp";

  create table profiles (
    id uuid references auth.users(id) on delete cascade primary key,
    name text not null,
    city text,
    industry text,
    photo_url text,
    created_at timestamptz default now()
  );

  create table profile_field_definitions (
    id uuid primary key default uuid_generate_v4(),
    label text not null,
    field_type text check (field_type in ('text', 'dropdown', 'number')) not null,
    is_global boolean default true,
    location_id uuid,
    display_order int default 0,
    is_active boolean default true,
    created_at timestamptz default now()
  );

  create table profile_field_values (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references profiles(id) on delete cascade,
    field_definition_id uuid references profile_field_definitions(id) on delete cascade,
    value text,
    is_visible boolean default true,
    unique(user_id, field_definition_id)
  );

  create table profile_images (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references profiles(id) on delete cascade,
    storage_path text not null,
    is_banner boolean default false,
    is_avatar boolean default false,
    display_order int default 0,
    created_at timestamptz default now()
  );

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

  alter table profile_field_definitions
    add constraint fk_field_location
    foreign key (location_id) references locations(id) on delete cascade;

  create table location_checkins (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references profiles(id) on delete cascade,
    location_id uuid references locations(id) on delete cascade,
    mode text check (mode in ('live', 'peeking')) not null,
    checked_in_at timestamptz default now(),
    checked_out_at timestamptz
  );

  create table friendships (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references profiles(id) on delete cascade,
    friend_id uuid references profiles(id) on delete cascade,
    connected_at timestamptz default now(),
    source text check (source in ('qr_scan', 'peek_invite', 'message')),
    unique(user_id, friend_id)
  );

  create table peek_invites (
    id uuid primary key default uuid_generate_v4(),
    sender_id uuid references profiles(id) on delete cascade,
    peeker_id uuid references profiles(id) on delete cascade,
    location_id uuid references locations(id) on delete cascade,
    sent_at timestamptz default now(),
    accepted_at timestamptz
  );

  create table feed_posts (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references profiles(id) on delete cascade,
    location_id uuid references locations(id) on delete cascade,
    content text not null,
    zone_tag text,
    created_at timestamptz default now()
  );

  create table feed_reactions (
    id uuid primary key default uuid_generate_v4(),
    post_id uuid references feed_posts(id) on delete cascade,
    user_id uuid references profiles(id) on delete cascade,
    reaction_type text default 'heart',
    created_at timestamptz default now(),
    unique(post_id, user_id)
  );

  create table contact_methods (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references profiles(id) on delete cascade,
    slot_order int not null check (slot_order between 1 and 6),
    type text check (type in ('whatsapp','linkedin','facebook','instagram','phone','link')) not null,
    value text,
    is_enabled boolean default false,
    unique(user_id, slot_order)
  );

  create table connections (
    id uuid primary key default uuid_generate_v4(),
    scanner_id uuid references profiles(id) on delete cascade,
    scannee_id uuid references profiles(id) on delete cascade,
    location_id uuid references locations(id),
    scanned_at timestamptz default now()
  );

  create table contact_taps (
    id uuid primary key default uuid_generate_v4(),
    connection_id uuid references connections(id) on delete cascade,
    method_type text not null,
    tapped_at timestamptz default now()
  );

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

  create table reward_claims (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references profiles(id) on delete cascade,
    reward_id uuid references rewards(id) on delete cascade,
    claimed_at timestamptz default now(),
    verified_by uuid references profiles(id)
  );

  create table engagement_events (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references profiles(id) on delete cascade,
    event_type text not null,
    points_earned int not null,
    created_at timestamptz default now()
  );

  create table feature_unlocks (
    id uuid primary key default uuid_generate_v4(),
    feature_name text unique not null,
    points_required int not null,
    description text
  );

  create table user_feature_access (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references profiles(id) on delete cascade,
    feature_name text not null,
    unlocked_at timestamptz default now(),
    granted_by uuid references profiles(id),
    unique(user_id, feature_name)
  );

  create table verification_tags (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references profiles(id) on delete cascade,
    location_id uuid references locations(id) on delete cascade,
    tag text not null,
    assigned_by uuid references profiles(id),
    assigned_at timestamptz default now()
  );

  alter publication supabase_realtime add table location_checkins;
  alter publication supabase_realtime add table feed_posts;
  alter publication supabase_realtime add table peek_invites;
  ```

- [ ] **Step 3: Create 002_seed_data.sql**

  Create `database/migrations/002_seed_data.sql`:

  ```sql
  insert into feature_unlocks (feature_name, points_required, description) values
    ('contact_slot_3_4', 100, '3rd and 4th contact method slots'),
    ('map_view', 250, 'Access to the map view'),
    ('contact_slot_5_6', 500, '5th and 6th contact method slots'),
    ('anonymous_peek', 1000, 'Browse without appearing on live feed'),
    ('extended_history', 2000, 'Extended history and custom field access')
  on conflict (feature_name) do nothing;

  insert into profile_field_definitions (label, field_type, is_global, display_order) values
    ('Age', 'number', true, 1),
    ('Fave Drink', 'text', true, 2),
    ('Nationality', 'text', true, 3),
    ('Bio', 'text', true, 4),
    ('On Friday Night I...', 'text', true, 5)
  on conflict do nothing;
  ```

- [ ] **Step 4: Apply to Supabase**

  Supabase dashboard → SQL Editor → run `001_initial_schema.sql`, then `002_seed_data.sql`.
  Expected: all tables visible in Table Editor, no errors.

- [ ] **Step 5: Configure Storage buckets**

  Supabase dashboard → Storage → New bucket:
  - `avatars` — public: false
  - `banners` — public: true
  - `qr-assets` — public: true

- [ ] **Step 6: Commit**

  ```bash
  git add database/
  git commit -m "feat: complete Supabase schema and seed data"
  ```

---

### Task 6: Replace Auth with Supabase

**Files:**
- Create: `The W App/Classes/WAPAuth.swift`
- Create: `The W AppTests/WAPAuthTests.swift`
- Modify: `The W App/Launch/LoginVC.swift`

**Interfaces:**
- Consumes: `WAPSupabase.shared.client` (Task 2), `KeychainHelper.Keys.authToken` (Task 3)
- Produces: `WAPAuth.signInWithPhone(phone:)`, `WAPAuth.verifyOTP(phone:token:)`, `WAPAuth.signInWithApple(idToken:nonce:)`, `WAPAuth.signInWithFacebook(accessToken:)`, `WAPAuth.signOut()`, `WAPAuth.currentUserID: String?`

- [ ] **Step 1: Write failing tests**

  Create `The W AppTests/WAPAuthTests.swift`:

  ```swift
  import XCTest
  @testable import TheWApp

  final class WAPAuthTests: XCTestCase {
      func testCurrentUserIDNilWhenNoToken() {
          KeychainHelper.delete(key: KeychainHelper.Keys.authToken)
          XCTAssertNil(WAPAuth.currentUserID)
      }

      func testCurrentUserIDReturnsSavedToken() {
          KeychainHelper.save(key: KeychainHelper.Keys.authToken, value: "uid-abc-123")
          XCTAssertEqual(WAPAuth.currentUserID, "uid-abc-123")
          KeychainHelper.delete(key: KeychainHelper.Keys.authToken)
      }
  }
  ```

- [ ] **Step 2: Run tests — expect fail**

  Cmd+U. Expected: FAIL — `WAPAuth` not found.

- [ ] **Step 3: Create WAPAuth.swift**

  Create `The W App/Classes/WAPAuth.swift`:

  ```swift
  import Foundation
  import Supabase

  enum WAPAuth {
      static var currentUserID: String? {
          KeychainHelper.load(key: KeychainHelper.Keys.authToken)
      }

      static func signInWithPhone(phone: String) async throws {
          try await WAPSupabase.shared.client.auth.signInWithOTP(phone: phone)
      }

      static func verifyOTP(phone: String, token: String) async throws {
          let session = try await WAPSupabase.shared.client.auth.verifyOTP(
              phone: phone, token: token, type: .sms
          )
          KeychainHelper.save(
              key: KeychainHelper.Keys.authToken,
              value: session.user.id.uuidString
          )
      }

      static func signInWithApple(idToken: String, nonce: String) async throws {
          let session = try await WAPSupabase.shared.client.auth.signInWithIdToken(
              credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
          )
          KeychainHelper.save(
              key: KeychainHelper.Keys.authToken,
              value: session.user.id.uuidString
          )
      }

      static func signInWithFacebook(accessToken: String) async throws {
          let session = try await WAPSupabase.shared.client.auth.signInWithIdToken(
              credentials: .init(provider: .facebook, idToken: accessToken)
          )
          KeychainHelper.save(
              key: KeychainHelper.Keys.authToken,
              value: session.user.id.uuidString
          )
      }

      static func signOut() async {
          try? await WAPSupabase.shared.client.auth.signOut()
          KeychainHelper.delete(key: KeychainHelper.Keys.authToken)
      }
  }
  ```

- [ ] **Step 4: Run tests — expect pass**

  Cmd+U. Expected: both WAPAuthTests PASS.

- [ ] **Step 5: Wire into LoginVC — phone login action**

  In `The W App/Launch/LoginVC.swift`, find the login button `@IBAction` and replace the URLSession body:

  ```swift
  @IBAction func loginTapped(_ sender: UIButton) {
      guard let phone = phoneField.text, !phone.isEmpty else {
          showAlert(Strings.alertEmpty); return
      }
      Task {
          do {
              try await WAPAuth.signInWithPhone(phone: phone)
              // Push OTP verification screen (built in Plan 2)
              showAlert("Verification code sent to \(phone)")
          } catch {
              showAlert(error.localizedDescription)
          }
      }
  }
  ```

- [ ] **Step 6: Wire into LoginVC — Apple Sign In callback**

  Find `authorizationController(controller:didCompleteWithAuthorization:)` and replace body:

  ```swift
  func authorizationController(controller: ASAuthorizationController,
                                didCompleteWithAuthorization authorization: ASAuthorization) {
      guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8),
            let nonce = currentNonce else { return }
      Task {
          do {
              try await WAPAuth.signInWithApple(idToken: idToken, nonce: nonce)
              navigateToHome()
          } catch {
              showAlert(error.localizedDescription)
          }
      }
  }
  ```

- [ ] **Step 7: Wire into LoginVC — Facebook callback**

  Find the FBSDKLoginKit result handler and replace:

  ```swift
  if let token = AccessToken.current?.tokenString {
      Task {
          do {
              try await WAPAuth.signInWithFacebook(accessToken: token)
              navigateToHome()
          } catch {
              showAlert(error.localizedDescription)
          }
      }
  }
  ```

  Delete all `URLSession` calls and `UserDefaults.standard.set(_, forKey: "Token")` lines from LoginVC.

- [ ] **Step 8: Build and smoke test**

  Cmd+B → Build Succeeded.
  Run on simulator → LoginVC appears → enter phone → tap login → alert shows "Verification code sent" → no crash.

- [ ] **Step 9: Commit**

  ```bash
  git add "The W App/Classes/WAPAuth.swift" "The W AppTests/WAPAuthTests.swift" "The W App/Launch/LoginVC.swift"
  git commit -m "feat: Supabase auth — phone OTP, Apple Sign In, Facebook"
  ```

---

### Task 7: Remove Dating-Specific Code

**Files:**
- Modify: any Swift file containing relationship/dating references

**Interfaces:**
- Produces: zero dating references in the codebase

- [ ] **Step 1: Find all dating references**

  ```bash
  grep -rn "Single\|\"Dating\"\|Married\|lookingFor\|Looking for\|Socializing\|Open to love\|Taken\b\|\"Fun\"\|relationship_status\|RelationshipStatus" \
    /Users/sr/thewapp-copy/ --include="*.swift" 2>/dev/null
  ```

- [ ] **Step 2: Remove each hit**

  For each file: delete the dating field, enum case, picker row, or UILabel. If removing breaks an initializer, supply a nil/empty default. Repeat until the grep above returns nothing.

- [ ] **Step 3: Build**

  Cmd+B → Build Succeeded.

- [ ] **Step 4: Commit**

  ```bash
  git add -A
  git commit -m "chore: remove all dating-specific fields and UI"
  ```

---

## Self-Review

- [x] All 7 tasks covered — rebrand, SPM, Keychain, Constants/Strings, schema, auth, dating removal
- [x] No TBDs or placeholders — every step has actual code
- [x] `WAPAuth` uses `WAPSupabase.shared.client` (Task 2) and `KeychainHelper.Keys.authToken` (Task 3) ✓
- [x] SQL FK order correct: `profiles` → `locations` → `profile_field_definitions` FK ✓
- [x] `alertWingout` → `alertCheckIn` in Strings ✓
- [x] Realtime enabled on `location_checkins`, `feed_posts`, `peek_invites` ✓
- [ ] **Known gap:** `RegisterVC` and `FcbRegisterVC` still contain URLSession calls — replaced entirely in Plan 2 (Onboarding). Leave non-functional for now.
