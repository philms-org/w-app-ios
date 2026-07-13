# Beta Phase 6 — EditProfileVC + UserProfileVC + NotificationVC

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire EditProfileVC to Supabase profile save + avatar upload; replace UserProfileVC PHP fetch with fetchProfile(); stub NotificationVC to empty state.

**Architecture:** Three self-contained tasks. EditProfileVC simplifies the storyboard-wired form (hiding dating-era fields) and replaces URLSession sendData() with async upsertProfile() + uploadAvatar(). UserProfileVC mirrors MyProfileVC's fetch pattern. NotificationVC becomes a static empty-state screen until a notifications table is built.

**Tech Stack:** Swift/UIKit/CocoaPods, Supabase Swift SDK v2 (≥2.0.0), Supabase Storage for avatar upload.

## Global Constraints

- Auth source of truth: `WAPAuth.currentUserID` — never `UserDefaults.getString(key: "Token")`
- Swift Concurrency: `Task { [weak self] in guard let self else { return } ... await MainActor.run {} }` — never `Task { @MainActor in }`
- No PHP calls — no `params.request(...)`, no URLSession to wingme.app
- No force-unwraps — use `guard let` / `if let`
- `[weak self]` in all Task closures and UIAlertAction handlers
- Safe cell casts: `guard let cell = ... as? CellType` — no force casts
- No XCTest target — verify via `xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS" build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5`
- Commit only specific files by name — never `git add .` or `git add -A`
- Project directory: `/Users/sr/wingme-copy`

---

### Task 1: EditProfileVC — Supabase profile save + avatar upload

**Files:**
- Modify: `Wing Me/My Profile/EditProfileVC.swift`
- Modify: `Wing Me/My Profile/EditProfilePicker.swift`
- Modify: `Wing Me/Classes/WAPData.swift`

**Interfaces:**
- Consumes: `WAPAuth.currentUserID: String?`
- Consumes: `WAPData.shared.upsertProfile(_ profile: WAPProfile) async throws`
- Produces: `WAPData.shared.uploadAvatar(imageData: Data, userId: String) async throws -> String`
- `WAPProfile` fields in scope: `id`, `displayName`, `email`, `phone`, `avatarURL`

**Context:**
`EditProfileVC` has storyboard IBOutlets for dating-era fields (`dateButton`, `agePrivateSwitch`, plus vars for `birthDate`, `gender`, `nationality`, `height`, `relationship`). These must be HIDDEN, not removed (removing storyboard outlets causes KVC crashes). The save action currently calls `sendData()` defined in `EditProfilePicker.swift`, which POSTs to PHP via URLSession. Replace the entire `sendData()` flow with Supabase. Avatar image capture already works via UIImagePickerController — only the upload needs replacing.

- [ ] **Step 1: Add `uploadAvatar` to WAPData**

  Open `Wing Me/Classes/WAPData.swift`. After the last function, add:

  ```swift
  func uploadAvatar(imageData: Data, userId: String) async throws -> String {
      let path = "\(userId)/avatar.jpg"
      try await client.storage
          .from("avatars")
          .upload(path: path, file: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))
      let url = try client.storage.from("avatars").getPublicURL(path: path)
      return url.absoluteString
  }
  ```

- [ ] **Step 2: Rewrite `EditProfileVC.swift`**

  Keep all IBOutlets (storyboard connections must stay). Only behaviour changes:

  a) In `viewDidLoad`, after `updateUI()`, hide the dating-era controls:
  ```swift
  override func viewDidLoad() {
      super.viewDidLoad()
      setKeyboard()
      updateUI()
      // Hide dating-era fields — WAPProfile has no gender/birthdate/agePrivacy
      dateButton.isHidden = true
      agePrivateSwitch.superview?.isHidden = true  // hide the containing row
  }
  ```

  b) Replace the `save` IBAction guard — only `displayName` (mapped from `nameTextField`) is required:
  ```swift
  @IBAction func save(_ sender: UIButton) {
      view.endEditing(true)
      guard !nameTextField.getText().isEmpty else {
          AlertClass().showWarningAlert(delegate: self, message: "Please enter your name.")
          return
      }
      saveButton.isHidden = true
      saveIndicator.startAnimating()
      saveProfile()
  }
  ```

  c) Add `saveProfile()` using the mandatory concurrency pattern:
  ```swift
  private func saveProfile() {
      guard let uid = WAPAuth.currentUserID else {
          saveButton.isHidden = false
          saveIndicator.stopAnimating()
          return
      }
      Task { [weak self] in
          guard let self else { return }
          do {
              var avatarURL: String? = self.imageURL.isEmpty ? nil : self.imageURL
              if let newImage = self.pickedImage,
                 let data = newImage.jpegData(compressionQuality: 0.8) {
                  avatarURL = try await WAPData.shared.uploadAvatar(imageData: data, userId: uid)
              }
              let profile = WAPProfile(
                  id: uid,
                  displayName: self.nameTextField.getText(),
                  email: self.emailTextField.getText().isEmpty ? nil : self.emailTextField.getText(),
                  phone: self.phoneTextField.getText().isEmpty ? nil : self.phoneTextField.getText(),
                  avatarURL: avatarURL
              )
              try await WAPData.shared.upsertProfile(profile)
              await MainActor.run {
                  self.saveButton.isHidden = false
                  self.saveIndicator.stopAnimating()
                  self.reloadProfile?()
                  AlertClass().showSuccessAlert(delegate: self, message: Strings.alertInfoEdited, action: {
                      self.dismiss(animated: true)
                  })
              }
          } catch {
              await MainActor.run {
                  self.saveButton.isHidden = false
                  self.saveIndicator.stopAnimating()
                  AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
              }
          }
      }
  }
  ```

  d) Add `var pickedImage: UIImage?` as a new stored property alongside the other vars.

  e) Change `var reloadProfile: (() -> ())!` to `var reloadProfile: (() -> ())?` — eliminates a force-unwrap crash if caller doesn't set it.

- [ ] **Step 3: Rewrite `EditProfilePicker.swift`**

  The file currently has `sendData()`, `sendError()`, `sendSuccess()`, `createRequest()`, and the picker delegate. Keep only the picker delegate and image-resize helper; remove all URLSession/PHP code.

  Replace the entire file with:

  ```swift
  import UIKit

  extension EditProfileVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

      func showPicker(button: UIButton) {
          let picker = UIImagePickerController()
          picker.delegate = self

          let sheet = UIAlertController(title: Strings.optionTitle, message: Strings.optionDetails, preferredStyle: .actionSheet)
          sheet.addAction(UIAlertAction(title: Strings.optionCamera, style: .default) { [weak self] _ in
              guard let self else { return }
              picker.sourceType = .camera
              self.present(picker, animated: true)
          })
          sheet.addAction(UIAlertAction(title: Strings.optionGallery, style: .default) { [weak self] _ in
              guard let self else { return }
              picker.sourceType = .photoLibrary
              self.present(picker, animated: true)
          })
          sheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))
          sheet.popoverPresentationController?.sourceView = button
          sheet.popoverPresentationController?.sourceRect = button.bounds
          sheet.popoverPresentationController?.permittedArrowDirections = .up
          present(sheet, animated: true)
      }

      func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
          picker.dismiss(animated: true)
          guard let image = info[.originalImage] as? UIImage else { return }
          let resized = resizedImage(image, to: CGSize(width: 300, height: 300))
          imageView.image = resized
          pickedImage = resized
      }

      func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
          picker.dismiss(animated: true)
      }

      private func resizedImage(_ image: UIImage, to size: CGSize) -> UIImage {
          let scale = min(size.width / image.size.width, size.height / image.size.height)
          let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
          UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
          image.draw(in: CGRect(origin: .zero, size: newSize))
          let result = UIGraphicsGetImageFromCurrentImageContext() ?? image
          UIGraphicsEndImageContext()
          return result
      }
  }
  ```

- [ ] **Step 4: Build**

  ```bash
  cd /Users/sr/wingme-copy
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS" build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

  ```bash
  git add "Wing Me/My Profile/EditProfileVC.swift" \
          "Wing Me/My Profile/EditProfilePicker.swift" \
          "Wing Me/Classes/WAPData.swift"
  git commit -m "feat: wire EditProfileVC to Supabase upsertProfile + Supabase Storage avatar upload"
  ```

---

### Task 2: UserProfileVC — replace PHP fetch with fetchProfile()

**Files:**
- Modify: `Wing Me/User Profile/UserProfileVC.swift`

**Interfaces:**
- Consumes: `WAPData.shared.fetchProfile(id: String) async throws -> WAPProfile`
- `var id: String` — target user UUID (set by caller before presentation)
- `var close: (() -> ())?` — preserved (used by ChatVC)
- `var fromChat: Bool` — preserved

**Context:**
`UserProfileVC` currently calls `get_user_info.php`, `block_user.php`, and `report_user.php`. The block/report Supabase methods do not exist in WAPData. Replace the profile fetch with `fetchProfile(id:)`. For block/report: replace both with an alert saying "Coming soon." Remove all PHP callbacks (`stopLoading`, `requestSuccess`, `block`, `blockStopLoading`, `blockSuccess`, `report`, `reportStopLoading`, `reportSuccess`). Also remove `getCountryName()` and `getGender()` — they served dating-era fields.

- [ ] **Step 1: Rewrite `request()` with async pattern**

  ```swift
  func request() {
      Task { [weak self] in
          guard let self else { return }
          do {
              let profile = try await WAPData.shared.fetchProfile(id: self.id)
              await MainActor.run {
                  self.displayProfile(profile)
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

- [ ] **Step 2: Add `displayProfile(_:)`**

  ```swift
  private func displayProfile(_ profile: WAPProfile) {
      nameLabel.text = profile.displayName
      checkmarkImageView.isHidden = !(profile.isVerified ?? false)

      if let url = profile.avatarURL, !url.isEmpty {
          imageView.imageFromServerURL(urlString: url)
      } else {
          imageView.image = UIImage(named: "icon_logo_profile")
      }

      cityView.isHidden = (profile.city ?? "").isEmpty
      cityLabel.text = profile.city ?? ""

      drinkView.isHidden = (profile.faveDrink ?? "").isEmpty
      drinkLabel.text = profile.faveDrink ?? ""

      fridayActivityView.isHidden = (profile.fridayNight ?? "").isEmpty
      fridayActivityLabel.text = profile.fridayNight ?? ""

      professionView.isHidden = (profile.profession ?? "").isEmpty
      professionLabel.text = profile.profession ?? ""

      // Dating-era fields — hide permanently (no WAPProfile equivalent)
      nationalityView.isHidden = true
      heightView.isHidden = true
      relationshipView.isHidden = true
      ageLabel.isHidden = true
      genderLabel.isHidden = true

      indicator.stopAnimating()
      scrollView.isHidden = false
  }
  ```

- [ ] **Step 3: Replace block/report with stubs**

  Replace `blockUser()` and `reportUser()` and all their PHP helpers with:

  ```swift
  func blockUser() {
      AlertClass().showWarningAlert(delegate: self, message: "Block is coming soon.", buttonTitle: "OK", action: {})
  }

  func reportUser() {
      AlertClass().showWarningAlert(delegate: self, message: "Report is coming soon.", buttonTitle: "OK", action: {})
  }
  ```

  Delete these functions entirely: `block()`, `blockStopLoading()`, `blockSuccess(_:)`, `report()`, `reportStopLoading()`, `reportSuccess(_:)`, `stopLoading()`, `requestSuccess(_:)`, `getCountryName(_:)`, `getGender(_:)`.

- [ ] **Step 4: Build and commit**

  ```bash
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS" build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
  git add "Wing Me/User Profile/UserProfileVC.swift"
  git commit -m "feat: wire UserProfileVC to fetchProfile(), stub block/report, hide dating-era fields"
  ```

---

### Task 3: NotificationVC — stub to empty state

**Files:**
- Modify: `Wing Me/Notifications/NotificationVC.swift`

**Context:**
`NotificationVC` is 57 lines and currently calls `get_notifications.php`. No Supabase notifications table exists yet. The VC is presented modally from `MyProfileVC` via storyboard (identifier "NotificationVC"). It has a `@IBAction func back` wired in storyboard — this must be preserved. Replace everything else with an empty-state label.

- [ ] **Step 1: Read current file**

  ```bash
  cat "Wing Me/Notifications/NotificationVC.swift"
  ```
  Note any additional `@IBOutlet` or `@IBAction` beyond `back` — they must stay as empty stubs if they exist, to avoid storyboard KVC crashes.

- [ ] **Step 2: Rewrite to empty state**

  ```swift
  import UIKit

  class NotificationVC: UIViewController {

      override func viewDidLoad() {
          super.viewDidLoad()
          view.backgroundColor = .systemBackground
          setupEmptyState()
      }

      private func setupEmptyState() {
          let label = UILabel()
          label.text = "No notifications yet."
          label.textColor = .secondaryLabel
          label.font = .systemFont(ofSize: 16)
          label.textAlignment = .center
          label.translatesAutoresizingMaskIntoConstraints = false
          view.addSubview(label)
          NSLayoutConstraint.activate([
              label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
              label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
          ])
      }

      @IBAction func back(_ sender: UIButton) {
          dismiss(animated: true)
      }
  }
  ```

  If the current file has additional `@IBOutlet` properties wired in the storyboard, keep them as `@IBOutlet weak var name: UIView!` stubs — do NOT remove them. If they are not wired in the storyboard (just class-level vars), they can be deleted.

- [ ] **Step 3: Build and commit**

  ```bash
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS" build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
  git add "Wing Me/Notifications/NotificationVC.swift"
  git commit -m "feat: stub NotificationVC to empty state, remove PHP notifications call"
  ```

---

## Supabase Storage prerequisite

Before Task 1's avatar upload works on a device/simulator, create the "avatars" storage bucket in the Supabase project. One-time manual step via the Supabase dashboard (Storage → New bucket → name: `avatars`, public: true). The implementer should note this in their report; it is not a migration file.
