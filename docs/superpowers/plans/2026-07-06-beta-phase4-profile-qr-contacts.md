# Beta Phase 4 — Profile + QR + Contact Methods Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire MyProfileVC, QRCodeVC, MyLinksVC, EditLinksVC, and UserLinksVC to real Supabase data — replacing all PHP stubs with WAPData calls so users can view their profile, generate a scannable QR code, and manage their 6 contact-method slots.

**Architecture:** All data is already in WAPData.swift (fetchProfile, fetchContactMethods, upsertContactMethod). Phase 4 is pure UI wiring — no new backend code. QR codes are generated on-device using Core Image's CIQRCodeGenerator filter. EditLinksVC is rebuilt as a fully programmatic VC (removing the stale storyboard content) to avoid storyboard XML surgery.

**Tech Stack:** Swift/UIKit, WAPData.shared, WAPAuth.currentUserID (Keychain), CoreImage (QR generation), no new dependencies.

## Global Constraints

- Backend: Supabase only — no URLSession calls to thewapp.app or any PHP endpoint
- Auth: user ID from `WAPAuth.currentUserID` → `KeychainHelper.load(key: KeychainHelper.Keys.authToken)` — never from UserDefaults
- Contact method types (exactly): `whatsapp`, `linkedin`, `facebook`, `instagram`, `phone`, `link`
- Contact method slot ordering (fixed): slot 1=whatsapp, 2=linkedin, 3=facebook, 4=instagram, 5=phone, 6=link
- Asset names: whatsapp→`image_whatsapp`, linkedin→`image_linkedin`, facebook→`image_facebook`, instagram→`image_instagram`, phone→`social_call`, link→`social_website`
- No XCTest target exists — verify correctness via Xcode build (Cmd+B → BUILD SUCCEEDED) + runtime smoke test in simulator
- YAGNI: no new features beyond what each task describes

---

### Task 1: MyProfileVC — Supabase profile loading + sign-out

**Files:**
- Modify: `The W App/My Profile/MyProfileVC.swift`

**Interfaces:**
- Consumes: `WAPData.shared.fetchProfile(id: String) async throws -> WAPProfile`
- Consumes: `WAPAuth.currentUserID: String?` and `WAPAuth.signOut() async`
- Consumes: `WAPProfile.displayName`, `.profession`, `.city`, `.faveDrink`, `.fridayNight`, `.avatarURL`, `.isVerified`

**IBOutlets retained (keep declarations — all exist in storyboard):**
`scrollView`, `imageView`, `nameLabel`, `checkmarkImageView`, `profileSetupView`, `editAccountView`, `editLocationView`, `generateUsersView`, `sendMessageView`, `eventsView`, `badgesView`, `settingsView`, `logoutButton`, `logoutIndicator`, `professionLabel`, `cityLabel`, `drinkLabel`, `fridayActivityLabel`, `indicator`

**IBOutlets to hide (keep @IBOutlet to avoid storyboard crash, just set `.isHidden = true`):**
`phoneLabel`, `emailLabel`, `nationalityLabel`, `ageLabel`, `genderLabel`, `heightLabel`, `relationshipLabel`

- [ ] **Step 1: Check MainVC for datingID properties**

  ```bash
  grep -n "datingID\|socialisingID\|networkingID" "The W App/Main/MainVC.swift" | head -10
  ```

  If found: keep the `editProfile(_:)` pass-through lines that read `delegate.datingID` etc.
  If not found: those lines will be compile errors after the `requestSuccess` removal — delete them from `editProfile(_:)` too.

- [ ] **Step 2: Replace `request()` and all PHP callback methods**

  Remove these methods entirely: `stopLoading()`, `requestSuccess(jsonObject:)`, `logoutError()`, `logoutSuccess(jsonObject:)`.

  Replace `request()` with:

  ```swift
  func request() {
      guard let uid = WAPAuth.currentUserID else { return }
      Task { @MainActor in
          do {
              let profile = try await WAPData.shared.fetchProfile(id: uid)
              displayProfile(profile)
          } catch {
              indicator.stopAnimating()
              AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
          }
      }
  }

  private func displayProfile(_ profile: WAPProfile) {
      nameLabel.text = profile.displayName
      professionLabel.text = profile.profession ?? ""
      cityLabel.text = profile.city ?? ""
      drinkLabel.text = profile.faveDrink ?? ""
      fridayActivityLabel.text = profile.fridayNight ?? ""

      if let url = profile.avatarURL, !url.isEmpty {
          imageView.imageFromServerURL(urlString: url)
      }

      checkmarkImageView.isHidden = !(profile.isVerified ?? false)

      // Hide dating-era fields that have no WAP equivalent
      phoneLabel.isHidden = true
      emailLabel.isHidden = true
      nationalityLabel.isHidden = true
      ageLabel.isHidden = true
      genderLabel.isHidden = true
      heightLabel.isHidden = true
      relationshipLabel.isHidden = true

      // Hide owner/master controls (not wired to WAPProfile yet)
      editLocationView.isHidden = true
      generateUsersView.isHidden = true
      sendMessageView.isHidden = true
      eventsView.isHidden = true
      badgesView.isHidden = true

      indicator.stopAnimating()
      scrollView.isHidden = false
  }
  ```

- [ ] **Step 3: Replace `logout()`**

  Remove the old `logout()` and replace with:

  ```swift
  func logout() {
      Task { @MainActor in
          await WAPAuth.signOut()
          delegate.logout()
          logoutButton.isHidden = false
          logoutIndicator.stopAnimating()
      }
  }
  ```

- [ ] **Step 4: Remove unused properties and helper methods**

  Remove these property declarations (no longer populated):
  ```swift
  var nationality = String()
  var birthDate = String()
  var agePrivacy = String()
  var gender = String()
  var height = String()
  var relationship = String()
  ```

  Remove these helper methods (were for PHP path):
  - `getCountryName(countryCode:)` — check it's not called elsewhere first
  - `getGender(gender:)` — check it's not called elsewhere first  
  - `getAge(date:)` — check it's not called elsewhere first

  ```bash
  grep -n "getCountryName\|getGender\|getAge\|showActionSheet" "The W App/My Profile/MyProfileVC.swift"
  ```

  Remove each method that is only called within MyProfileVC and no longer referenced.

- [ ] **Step 5: Build — fix any remaining compilation errors**

  Open `The W App.xcworkspace` → Cmd+B.

  Common errors and fixes:
  - `"value of type 'MyProfileVC' has no member 'logoutError'"` — remove the call site
  - `"value of type 'MyProfileVC' has no member 'logoutSuccess'"` — remove the call site
  - `"value of type 'MyVC' has no member 'datingID'"` — remove that line from `editProfile(_:)`

  Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Commit**

  ```bash
  git add "The W App/My Profile/MyProfileVC.swift"
  git commit -m "feat: wire MyProfileVC to Supabase fetchProfile, fix sign-out"
  ```

---

### Task 2: QRCodeVC — real Core Image QR code

**Files:**
- Modify: `The W App/QR Code/QRCodeVC.swift`

**Interfaces:**
- Consumes: `WAPAuth.currentUserID: String?`

**Storyboard context (do not modify storyboard):**
View hierarchy in QRCodeVC storyboard scene:
- `view` (semi-transparent black)
  - UIViewDesignable card 300×300 ← `view.subviews[0]`
    - UIImageView 220×220, currently shows `icon_qr_code` ← `view.subviews[0].subviews[0]`
  - Share button container ← `view.subviews[1]`

Access the image view at runtime as: `view.subviews.first?.subviews.first as? UIImageView`

- [ ] **Step 1: Rewrite QRCodeVC.swift**

  ```swift
  import UIKit
  import CoreImage

  class QRCodeVC: UIViewController {

      override func viewDidLoad() {
          super.viewDidLoad()
          generateAndDisplayQR()
      }

      override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
          dismiss(animated: true)
      }

      @IBAction func share(_ sender: UIButton) {
          guard let uid = WAPAuth.currentUserID else { return }
          let url = "openWAPContact://id=\(uid)"
          let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
          activity.popoverPresentationController?.sourceView = sender
          activity.popoverPresentationController?.sourceRect = sender.bounds
          activity.popoverPresentationController?.permittedArrowDirections = .up
          present(activity, animated: true, completion: nil)
      }

      private func generateAndDisplayQR() {
          guard let uid = WAPAuth.currentUserID,
                let imageView = view.subviews.first?.subviews.first as? UIImageView else { return }
          imageView.image = qrImage(from: "openWAPContact://id=\(uid)")
          imageView.contentMode = .scaleAspectFit
      }

      private func qrImage(from string: String) -> UIImage? {
          guard let data = string.data(using: .utf8),
                let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
          filter.setValue(data, forKey: "inputMessage")
          filter.setValue("H", forKey: "inputCorrectionLevel")
          guard let output = filter.outputImage else { return nil }
          let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
          return UIImage(ciImage: scaled)
      }
  }
  ```

- [ ] **Step 2: Build and smoke test**

  Cmd+B → BUILD SUCCEEDED.

  Run in simulator (Cmd+R). Tap QR button on profile. Expected: real black-and-white QR code appears inside the white card instead of the static icon.

- [ ] **Step 3: Commit**

  ```bash
  git add "The W App/QR Code/QRCodeVC.swift"
  git commit -m "feat: generate real QR code in QRCodeVC using CIQRCodeGenerator"
  ```

---

### Task 3: MyLinksVC + LinkCell — load contact methods from WAPData

**Files:**
- Modify: `The W App/QR Code/LinkCell.swift`
- Modify: `The W App/QR Code/MyLinksVC.swift`

**Interfaces:**
- Consumes: `WAPData.shared.fetchContactMethods(userId: String) async throws -> [WAPContactMethod]`
- Consumes: `WAPContactMethod.type: String`, `.value: String?`, `.isEnabled: Bool`
- Consumes: `WAPAuth.currentUserID: String?`
- Produces: `LinkCell.configure(method: WAPContactMethod)` — used by Task 5
- Produces: `LinkCell.assetName(for type: String) -> String` — used by Task 4 and Task 5

- [ ] **Step 1: Rewrite LinkCell.swift**

  ```swift
  import UIKit

  class LinkCell: UICollectionViewCell {

      @IBOutlet weak var linkImageView: UIImageView!

      func configure(method: WAPContactMethod) {
          linkImageView.image = UIImage(named: LinkCell.assetName(for: method.type))
          alpha = method.isEnabled ? 1.0 : 0.3
      }

      // Kept for any remaining callers during transition
      func updateCell(item: LinkStruct) {
          linkImageView.image = item.image
          alpha = 1.0
      }

      static func assetName(for type: String) -> String {
          switch type {
          case "whatsapp":  return "image_whatsapp"
          case "linkedin":  return "image_linkedin"
          case "facebook":  return "image_facebook"
          case "instagram": return "image_instagram"
          case "phone":     return "social_call"
          default:          return "social_website"
          }
      }
  }

  struct LinkStruct {
      let image: UIImage
      let url: String
  }
  ```

- [ ] **Step 2: Check storyboard collectionView outlet for MyLinksVC**

  ```bash
  grep -n "collectionView\|XYU-fs-U6C" "The W App/Base.lproj/Main.storyboard" | grep -i "outlet\|collection" | head -5
  ```

  If an outlet named "collectionView" exists in the storyboard scene: keep the `@IBOutlet` declaration.
  If no outlet: add `viewDidLoad` with programmatic lookup (shown in Step 3 below).

- [ ] **Step 3: Rewrite MyLinksVC.swift**

  ```swift
  import UIKit

  class MyLinksVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

      @IBOutlet weak var collectionView: UICollectionView!

      private static let slotTypes = ["whatsapp", "linkedin", "facebook", "instagram", "phone", "link"]

      private var methods: [WAPContactMethod] = MyLinksVC.slotTypes.enumerated().map { i, type in
          WAPContactMethod(id: "", userId: "", slotOrder: i + 1, type: type, value: nil, isEnabled: false)
      }

      override func viewDidLoad() {
          super.viewDidLoad()
          // Fallback if storyboard outlet is not wired
          if collectionView == nil {
              collectionView = view.subviews.flatMap { $0.subviews }
                  .compactMap { $0 as? UICollectionView }.first
          }
      }

      override func viewWillAppear(_ animated: Bool) {
          super.viewWillAppear(animated)
          loadMethods()
      }

      private func loadMethods() {
          guard let uid = WAPAuth.currentUserID else { return }
          Task { @MainActor in
              do {
                  let fetched = try await WAPData.shared.fetchContactMethods(userId: uid)
                  methods = MyLinksVC.slotTypes.enumerated().map { i, type in
                      fetched.first { $0.type == type }
                          ?? WAPContactMethod(id: "", userId: uid,
                                             slotOrder: i + 1, type: type,
                                             value: nil, isEnabled: false)
                  }
                  collectionView.reloadData()
              } catch {
                  AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
              }
          }
      }

      // MARK: - UICollectionViewDataSource

      func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
          methods.count
      }

      func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
          let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LinkCell", for: indexPath) as! LinkCell
          cell.configure(method: methods[indexPath.row])
          return cell
      }

      func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
          let side = collectionView.frame.width / 3
          return CGSize(width: side, height: side)
      }

      // MARK: - UICollectionViewDelegate

      func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
          let method = methods[indexPath.row]
          guard method.isEnabled, let value = method.value, !value.isEmpty else { return }
          openMethod(type: method.type, value: value)
      }

      private func openMethod(type: String, value: String) {
          let urlString: String
          switch type {
          case "whatsapp":
              urlString = "https://wa.me/\(value.filter { $0.isNumber })"
          case "phone":
              urlString = "tel:\(value.filter { $0.isNumber })"
          case "linkedin":
              urlString = value.hasPrefix("http") ? value : "https://linkedin.com/in/\(value)"
          case "facebook":
              urlString = value.hasPrefix("http") ? value : "https://facebook.com/\(value)"
          case "instagram":
              urlString = value.hasPrefix("http") ? value : "https://instagram.com/\(value)"
          default:
              urlString = value.hasPrefix("http") ? value : "https://\(value)"
          }
          if let url = URL(string: urlString) {
              UIApplication.shared.open(url)
          }
      }

      // MARK: - IBActions

      @IBAction func back(_ sender: UIButton) {
          dismiss(animated: true)
      }

      @IBAction func edit(_ sender: UIButton) {
          let vc = EditLinksVC()
          vc.modalPresentationStyle = .currentContext
          present(vc, animated: true)
      }
  }
  ```

- [ ] **Step 4: Build and verify**

  Cmd+B → BUILD SUCCEEDED. Run in simulator, open My Links. Verify 6 slots appear (dimmed = no value/disabled). Tapping an enabled slot with a set value opens the URL.

- [ ] **Step 5: Commit**

  ```bash
  git add "The W App/QR Code/LinkCell.swift" "The W App/QR Code/MyLinksVC.swift"
  git commit -m "feat: wire MyLinksVC to WAPData contact methods, add configure(method:) to LinkCell"
  ```

---

### Task 4: EditLinksVC — programmatic 6-slot contact editor

**Files:**
- Modify: `The W App/QR Code/EditLinksVC.swift` (full rewrite, programmatic UI)

**Interfaces:**
- Consumes: `WAPData.shared.fetchContactMethods(userId: String) async throws -> [WAPContactMethod]`
- Consumes: `WAPData.shared.upsertContactMethod(_ method: WAPContactMethod) async throws`
- Consumes: `WAPAuth.currentUserID: String?`
- Consumes: `LinkCell.assetName(for type: String) -> String`
- Consumes: `WAPContactMethod(id:userId:slotOrder:type:value:isEnabled:)` memberwise init

**Why programmatic:** MyLinksVC already uses `EditLinksVC()` (no storyboard). The existing storyboard scene for EditLinksVC has unrelated content from a The W App profile edit form. `viewDidLoad` wipes all storyboard subviews and rebuilds from scratch.

**Sentinel for new slots:** `id: ""` means the slot has never been saved to DB. On save, a new UUID is generated. Slots with `id != ""` were fetched from DB and upsert by PK updates them in-place.

- [ ] **Step 1: Rewrite EditLinksVC.swift**

  ```swift
  import UIKit

  class EditLinksVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

      private let tableView = UITableView(frame: .zero, style: .plain)
      private var rowFields:   [UITextField] = []
      private var rowSwitches: [UISwitch] = []
      private var methods:     [WAPContactMethod] = []

      private static let slots: [(type: String, label: String)] = [
          ("whatsapp",  "WhatsApp"),
          ("linkedin",  "LinkedIn"),
          ("facebook",  "Facebook"),
          ("instagram", "Instagram"),
          ("phone",     "Phone"),
          ("link",      "Link / Website"),
      ]

      override func viewDidLoad() {
          super.viewDidLoad()
          view.subviews.forEach { $0.removeFromSuperview() }
          view.backgroundColor = .systemBackground
          setupHeader()
          setupTableView()
          loadMethods()
      }

      // MARK: - Layout

      private func setupHeader() {
          let close = UIButton(type: .system)
          close.setTitle("✕", for: .normal)
          close.titleLabel?.font = .systemFont(ofSize: 20)
          close.translatesAutoresizingMaskIntoConstraints = false
          close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

          let save = UIButton(type: .system)
          save.setTitle("Save", for: .normal)
          save.titleLabel?.font = .boldSystemFont(ofSize: 17)
          save.translatesAutoresizingMaskIntoConstraints = false
          save.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
          save.tag = 99  // tag used in saveTapped to re-enable after async

          view.addSubview(close)
          view.addSubview(save)
          NSLayoutConstraint.activate([
              close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
              close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
              save.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
              save.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
          ])
      }

      private func setupTableView() {
          tableView.translatesAutoresizingMaskIntoConstraints = false
          tableView.dataSource = self
          tableView.delegate = self
          tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SlotCell")
          tableView.rowHeight = 70
          tableView.separatorInset = .zero
          tableView.allowsSelection = false
          view.addSubview(tableView)
          NSLayoutConstraint.activate([
              tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
              tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
              tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
              tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
          ])
      }

      // MARK: - Data

      private func loadMethods() {
          guard let uid = WAPAuth.currentUserID else { return }
          Task { @MainActor in
              do {
                  let fetched = try await WAPData.shared.fetchContactMethods(userId: uid)
                  methods = EditLinksVC.slots.enumerated().map { i, slot in
                      fetched.first { $0.type == slot.type }
                          ?? WAPContactMethod(id: "", userId: uid,
                                             slotOrder: i + 1, type: slot.type,
                                             value: nil, isEnabled: false)
                  }
                  tableView.reloadData()
              } catch {
                  AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
              }
          }
      }

      // MARK: - UITableViewDataSource

      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          EditLinksVC.slots.count
      }

      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          let cell = tableView.dequeueReusableCell(withIdentifier: "SlotCell", for: indexPath)
          cell.contentView.subviews.forEach { $0.removeFromSuperview() }

          let slot   = EditLinksVC.slots[indexPath.row]
          let method = methods.isEmpty ? nil : methods[indexPath.row]

          let icon = UIImageView(image: UIImage(named: LinkCell.assetName(for: slot.type)))
          icon.contentMode = .scaleAspectFit
          icon.translatesAutoresizingMaskIntoConstraints = false
          icon.widthAnchor.constraint(equalToConstant: 32).isActive = true
          icon.heightAnchor.constraint(equalToConstant: 32).isActive = true

          let label = UILabel()
          label.text = slot.label
          label.font = .systemFont(ofSize: 14, weight: .medium)
          label.translatesAutoresizingMaskIntoConstraints = false
          label.widthAnchor.constraint(equalToConstant: 90).isActive = true

          let field = UITextField()
          field.placeholder = slot.type == "phone" ? "+1 234 567 8900" : "URL or handle"
          field.text = method?.value ?? ""
          field.font = .systemFont(ofSize: 13)
          field.borderStyle = .roundedRect
          field.autocapitalizationType = .none
          field.autocorrectionType = .no
          field.keyboardType = slot.type == "phone" ? .phonePad : .URL
          field.tag = indexPath.row

          let toggle = UISwitch()
          toggle.isOn = method?.isEnabled ?? false
          toggle.tag = indexPath.row
          toggle.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)

          // Ensure arrays are large enough
          while rowFields.count   <= indexPath.row { rowFields.append(UITextField()) }
          while rowSwitches.count <= indexPath.row { rowSwitches.append(UISwitch()) }
          rowFields[indexPath.row]   = field
          rowSwitches[indexPath.row] = toggle

          let stack = UIStackView(arrangedSubviews: [icon, label, field, toggle])
          stack.axis = .horizontal
          stack.spacing = 10
          stack.alignment = .center
          stack.translatesAutoresizingMaskIntoConstraints = false

          cell.contentView.addSubview(stack)
          NSLayoutConstraint.activate([
              stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
              stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
              stack.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
          ])
          return cell
      }

      // MARK: - Actions

      @objc private func switchChanged(_ sender: UISwitch) {
          guard sender.tag < methods.count else { return }
          methods[sender.tag].isEnabled = sender.isOn
      }

      @objc private func saveTapped() {
          guard let uid = WAPAuth.currentUserID else { return }
          view.endEditing(true)

          // Capture text field values into methods array
          for (i, field) in rowFields.enumerated() where i < methods.count {
              let text = field.text ?? ""
              methods[i].value = text.isEmpty ? nil : text
          }

          if let saveBtn = view.viewWithTag(99) as? UIButton { saveBtn.isEnabled = false }

          Task { @MainActor in
              do {
                  for (i, method) in methods.enumerated() {
                      let isNew   = method.id.isEmpty
                      let hasValue = !(method.value ?? "").isEmpty
                      guard !isNew || hasValue else { continue }   // skip empty new slots
                      var m = method
                      if isNew {
                          m = WAPContactMethod(id: UUID().uuidString, userId: uid,
                                              slotOrder: i + 1, type: m.type,
                                              value: m.value, isEnabled: m.isEnabled)
                      }
                      try await WAPData.shared.upsertContactMethod(m)
                  }
                  dismiss(animated: true)
              } catch {
                  if let saveBtn = view.viewWithTag(99) as? UIButton { saveBtn.isEnabled = true }
                  AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
              }
          }
      }

      @objc private func closeTapped() {
          dismiss(animated: true)
      }
  }
  ```

- [ ] **Step 2: Build and smoke test**

  Cmd+B → BUILD SUCCEEDED.

  Run in simulator. Open My Links → tap Edit. Expected:
  - Screen appears with 6 rows (WhatsApp, LinkedIn, Facebook, Instagram, Phone, Link/Website)
  - Each row shows icon + label + text field + toggle
  - ✕ button dismisses without saving
  - Enter "testhandle" in Instagram row, toggle it on, tap Save → dismissed
  - Re-open Edit: "testhandle" still there, toggle still on

- [ ] **Step 3: Commit**

  ```bash
  git add "The W App/QR Code/EditLinksVC.swift"
  git commit -m "feat: rebuild EditLinksVC as programmatic 6-slot contact method editor"
  ```

---

### Task 5: UserLinksVC — another user's enabled contact methods

**Files:**
- Modify: `The W App/QR Code/UserLinksVC.swift`

**Interfaces:**
- Consumes: `WAPData.shared.fetchContactMethods(userId: String) async throws -> [WAPContactMethod]`
- Consumes: `LinkCell.configure(method: WAPContactMethod)` — from Task 3
- Consumes: `var id: String` — already declared in existing UserLinksVC; UUID passed from AppDelegate deep link

- [ ] **Step 1: Rewrite UserLinksVC.swift**

  ```swift
  import UIKit

  class UserLinksVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

      @IBOutlet weak var collectionView: UICollectionView!

      var id = String()   // user UUID passed from AppDelegate deep link

      private var methods: [WAPContactMethod] = []

      override func viewDidLoad() {
          super.viewDidLoad()
          if collectionView == nil {
              collectionView = view.subviews.flatMap { $0.subviews }
                  .compactMap { $0 as? UICollectionView }.first
          }
      }

      override func viewWillAppear(_ animated: Bool) {
          super.viewWillAppear(animated)
          guard !id.isEmpty else { return }
          loadMethods()
      }

      private func loadMethods() {
          Task { @MainActor in
              do {
                  let fetched = try await WAPData.shared.fetchContactMethods(userId: id)
                  methods = fetched.filter { $0.isEnabled && !($0.value ?? "").isEmpty }
                  collectionView?.reloadData()
              } catch {
                  AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
              }
          }
      }

      // MARK: - UICollectionViewDataSource

      func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
          methods.count
      }

      func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
          let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LinkCell", for: indexPath) as! LinkCell
          cell.configure(method: methods[indexPath.row])
          return cell
      }

      func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
          let side = collectionView.frame.width / 3
          return CGSize(width: side, height: side)
      }

      // MARK: - UICollectionViewDelegate

      func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
          let method = methods[indexPath.row]
          guard let value = method.value, !value.isEmpty else { return }
          openMethod(type: method.type, value: value)
      }

      private func openMethod(type: String, value: String) {
          let urlString: String
          switch type {
          case "whatsapp":
              urlString = "https://wa.me/\(value.filter { $0.isNumber })"
          case "phone":
              urlString = "tel:\(value.filter { $0.isNumber })"
          case "linkedin":
              urlString = value.hasPrefix("http") ? value : "https://linkedin.com/in/\(value)"
          case "facebook":
              urlString = value.hasPrefix("http") ? value : "https://facebook.com/\(value)"
          case "instagram":
              urlString = value.hasPrefix("http") ? value : "https://instagram.com/\(value)"
          default:
              urlString = value.hasPrefix("http") ? value : "https://\(value)"
          }
          if let url = URL(string: urlString) {
              UIApplication.shared.open(url)
          }
      }

      // MARK: - IBActions

      @IBAction func back(_ sender: UIButton) {
          dismiss(animated: true)
      }

      @IBAction func share(_ sender: UIButton) {
          guard !id.isEmpty else { return }
          let url = "openWAPContact://id=\(id)"
          let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
          activity.popoverPresentationController?.sourceView = sender
          activity.popoverPresentationController?.sourceRect = sender.bounds
          activity.popoverPresentationController?.permittedArrowDirections = .up
          present(activity, animated: true, completion: nil)
      }
  }
  ```

- [ ] **Step 2: Build and verify**

  Cmd+B → BUILD SUCCEEDED.

  In simulator: the UserLinksVC is invoked via the `openWAPContact://id=<uuid>` deep link from AppDelegate. To smoke-test: temporarily set `id = "<your-test-user-uuid>"` in `viewWillAppear` before the `guard` to force load, verify cells appear and tapping opens URLs.

- [ ] **Step 3: Commit**

  ```bash
  git add "The W App/QR Code/UserLinksVC.swift"
  git commit -m "feat: wire UserLinksVC to WAPData contact methods by user ID"
  ```

---

## Self-Review

**Spec coverage (WAP design spec Section 5):**
- ✅ Profile: name, profession, city, fave drink, friday night — Task 1
- ✅ Logout → Supabase sign-out — Task 1
- ✅ QR code generation for current user — Task 2
- ✅ 2×3 contact grid (WhatsApp, LinkedIn, Facebook, Instagram, Phone, Link) — Task 3
- ✅ Enabled/disabled state shown (dimmed = disabled) — Task 3
- ✅ Tapping enabled slot opens contact URL — Task 3 + Task 5
- ✅ Edit mode: URL/handle input + enable toggle per slot — Task 4
- ✅ Viewing another user's links by ID — Task 5
- ⏭ Contact slot unlocking via engagement bar (slots 3+4 at Level 1, 5+6 at Level 3) — Phase 5
- ⏭ QR scan → `connections` row in DB — Phase 6
- ⏭ Method tap → `contact_taps` row in DB — Phase 6

**Placeholder scan:** None — all steps contain complete code.

**Type consistency:** `WAPContactMethod` used across Tasks 3/4/5. `LinkCell.configure(method:)` and `LinkCell.assetName(for:)` defined in Task 3, consumed in Tasks 4 and 5. `openMethod(type:value:)` logic is duplicated between MyLinksVC and UserLinksVC intentionally (YAGNI — refactoring to shared util is premature).
