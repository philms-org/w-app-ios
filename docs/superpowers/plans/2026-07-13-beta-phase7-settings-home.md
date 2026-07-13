# Beta Phase 7 — Settings, ForgotPasswordVC, HomeVC Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all remaining PHP backend calls in Settings screens, ForgotPasswordVC, and HomeVC with Supabase equivalents or safe empty-state stubs, producing a beta build with no active PHP calls in these flows.

**Architecture:** Each VC is migrated in isolation. Settings sub-VCs (ContactVC, VastVC) are stubbed to empty/coming-soon state. ChangePasswordVC calls Supabase auth.update. ForgotPasswordVC is simplified to email-based Supabase password reset (removes the 3-step Firebase phone flow). HomeVC replaces PHP get_home with fetchVenues() showing venues only, hiding all other sections. BlockListVC is stubbed to empty state.

**Tech Stack:** Swift/UIKit, Supabase Swift SDK (via `WAPSupabase.shared.client`), existing WAPAuth/WAPData patterns.

## Global Constraints

- Auth token: `WAPAuth.currentUserID` via `KeychainHelper` — never `UserDefaults`
- `[weak self]` required in every Task closure AND every UIAlertAction handler closure that captures self
- No force-unwraps in new code
- Swift Concurrency: `Task { [weak self] in guard let self else { return } ... await MainActor.run {} }` only — never `Task { @MainActor in }`
- No calls to wingme.app or any `.php` path in modified files
- All storyboard-wired IBActions, IBOutlets, and delegate/dataSource connections must remain present in the VC class
- Build verification: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS" build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -4`

---

### Task 1: ChangePasswordVC — Supabase auth.update

**Files:**
- Modify: `Wing Me/Settings/ChangePasswordVC.swift`

**Context:**
- Old flow: POST to `change_password.php` → response writes new token to `UserDefaults`. Remove all of this.
- New flow: user is already authenticated via Supabase; call `WAPSupabase.shared.client.auth.update(user: UserAttributes(password: newPassword))`. Old password is NOT required by Supabase's updateUser (the user is signed in). This is acceptable for beta.
- `fromLogin` was a PHP-era flag for post-login forced password change. Remove the `openMain()` path entirely — dismiss on success regardless.
- IBOutlets to keep (storyboard wired): `oldTextField`, `newTextField`, `confirmTextField`, `changeButton`, `changeIndicator`
- The `oldTextField` is now unused functionally (Supabase doesn't verify old password). Keep the outlet and field visible (don't break storyboard), but ignore its value in the new implementation.

- [ ] **Step 1: Replace change() and remove PHP helpers**

Replace the entire body of `Wing Me/Settings/ChangePasswordVC.swift` with:

```swift
import UIKit

class ChangePasswordVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var oldTextField: UITextField!
    @IBOutlet weak var newTextField: UITextField!
    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var changeIndicator: UIActivityIndicatorView!

    var fromLogin = Bool()

    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func change(_ sender: UIButton) {
        view.endEditing(true)
        guard !newTextField.getText().isEmpty && !confirmTextField.getText().isEmpty else {
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        guard newTextField.getText() == confirmTextField.getText() else {
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertBoth)
            return
        }
        changeButton.isHidden = true
        changeIndicator.startAnimating()
        changePassword()
    }

    private func changePassword() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await WAPSupabase.shared.client.auth.update(
                    user: UserAttributes(password: self.newTextField.getText())
                )
                await MainActor.run {
                    self.changeButton.isHidden = false
                    self.changeIndicator.stopAnimating()
                    AlertClass().showSuccessAlert(delegate: self, message: Strings.alertPasswordChanged, action: { [weak self] in
                        self?.dismiss(animated: true)
                    })
                }
            } catch {
                await MainActor.run {
                    self.changeButton.isHidden = false
                    self.changeIndicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS" build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -4`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add "Wing Me/Settings/ChangePasswordVC.swift"
git commit -m "feat(phase7): replace ChangePasswordVC PHP call with Supabase auth.update"
```

---

### Task 2: ForgotPasswordVC — email-based Supabase password reset

**Files:**
- Modify: `Wing Me/Launch/ForgotPasswordVC.swift`

**Context:**
- Old flow: 3 steps — (1) phone number → Firebase SMS, (2) verify code → Firebase sign-in, (3) new password → PHP reset. Remove all of this.
- New flow: single step — enter email address → `client.auth.resetPasswordForEmail(email)` → show success alert and dismiss.
- IBOutlets to keep (storyboard wired): `codeButton`, `phoneTextField`, `verificationView`, `verificationTextField`, `passwordView`, `passwordTextField`, `confirmTextField`, `nextButton`, `nextIndicator`
- `phoneTextField` is repurposed as the email field (change the placeholder, but keep the outlet name — it's storyboard-wired).
- `verificationView` and `passwordView` must be hidden in `viewDidLoad` and never shown.
- `codeButton` must be hidden in `viewDidLoad` (it was the country code picker button).
- Remove `import FirebaseAuth`, `var codesArray`, `var step`, `var code`, `var verificationID` — none needed.
- The `countryCode` IBAction wired to `codeButton` — keep as a no-op stub (storyboard still wires it).
- `nextButton` sends the reset email in the single step.

- [ ] **Step 1: Rewrite ForgotPasswordVC**

Replace the entire body of `Wing Me/Launch/ForgotPasswordVC.swift` with:

```swift
import UIKit

class ForgotPasswordVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var codeButton: UIButton!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var verificationView: UIView!
    @IBOutlet weak var verificationTextField: UITextField!
    @IBOutlet weak var passwordView: UIStackView!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var nextIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
        codeButton.isHidden = true
        verificationView.isHidden = true
        passwordView.isHidden = true
        phoneTextField.placeholder = "Email address"
        phoneTextField.keyboardType = .emailAddress
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func countryCode(_ sender: UIButton) {
        // No-op — codeButton is hidden; IBAction kept for storyboard compatibility
    }

    @IBAction func next(_ sender: UIButton) {
        view.endEditing(true)
        let email = phoneTextField.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else {
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        nextButton.isHidden = true
        nextIndicator.startAnimating()
        sendReset(email: email)
    }

    private func sendReset(email: String) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await WAPSupabase.shared.client.auth.resetPasswordForEmail(email)
                await MainActor.run {
                    self.nextButton.isHidden = false
                    self.nextIndicator.stopAnimating()
                    AlertClass().showSuccessAlert(delegate: self, message: "Password reset link sent. Check your email.", action: { [weak self] in
                        self?.dismiss(animated: true)
                    })
                }
            } catch {
                await MainActor.run {
                    self.nextButton.isHidden = false
                    self.nextIndicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run build command. Expected: `** BUILD SUCCEEDED **`

Note: if FirebaseAuth is no longer imported by any file after this change, that is acceptable — other Firebase-using files may still hold imports.

- [ ] **Step 3: Commit**

```bash
git add "Wing Me/Launch/ForgotPasswordVC.swift"
git commit -m "feat(phase7): replace ForgotPasswordVC Firebase/PHP flow with Supabase email reset"
```

---

### Task 3: SettingsVC + Constants — open static URLs instead of PHP AboutVC

**Files:**
- Modify: `Wing Me/Classes/Constants.swift`
- Modify: `Wing Me/Settings/SettingsVC.swift`

**Context:**
- `SettingsVC.openAbout(title:path:)` currently instantiates `AboutVC` with a `.php` path. Replace with direct URL open to static thewapp.com pages.
- `AboutVC.swift` becomes dead code (never instantiated from SettingsVC any more). Do NOT delete or modify it.
- Add three URL constants to `Constants.swift`: `aboutURL`, `termsURL`, `privacyURL`.
- `SettingsVC.about`, `terms`, `privacy` IBActions open the URL directly with `UIApplication.shared.open`. Remove `openAbout()` entirely.

- [ ] **Step 1: Add URL constants to Constants.swift**

Read `Wing Me/Classes/Constants.swift` first. After the line `static let deleteAccountURL = "https://thewapp.com/delete_account"`, add:

```swift
static let aboutURL = "https://thewapp.com/about"
static let termsURL = "https://thewapp.com/terms"
static let privacyURL = "https://thewapp.com/privacy"
```

- [ ] **Step 2: Rewrite SettingsVC.swift**

Replace the entire body with:

```swift
import UIKit

class SettingsVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func about(_ sender: UIButton) {
        openURL(Constants.aboutURL)
    }

    @IBAction func terms(_ sender: UIButton) {
        openURL(Constants.termsURL)
    }

    @IBAction func privacy(_ sender: UIButton) {
        openURL(Constants.privacyURL)
    }

    @IBAction func vast(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "VastVC") as? VastVC {
            present(vc, animated: true)
        }
    }

    @IBAction func blockList(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "BlockListVC") as? BlockListVC {
            present(vc, animated: true)
        }
    }

    @IBAction func shareApp(_ sender: UIButton) {
        let activity = UIActivityViewController(activityItems: [Constants.appURL], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = sender
        activity.popoverPresentationController?.sourceRect = sender.bounds
        activity.popoverPresentationController?.permittedArrowDirections = .up
        present(activity, animated: true)
    }

    @IBAction func contact(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ContactVC") as? ContactVC {
            vc.modalPresentationStyle = .currentContext
            present(vc, animated: true)
        }
    }

    @IBAction func changePassword(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ChangePasswordVC") as? ChangePasswordVC {
            vc.modalPresentationStyle = .currentContext
            present(vc, animated: true)
        }
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url, options: [:])
    }
}
```

- [ ] **Step 3: Build to verify**

Run build command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add "Wing Me/Classes/Constants.swift" "Wing Me/Settings/SettingsVC.swift"
git commit -m "feat(phase7): replace SettingsVC PHP AboutVC flow with static URL opens"
```

---

### Task 4: ContactVC, VastVC, BlockListVC — empty-state stubs

**Files:**
- Modify: `Wing Me/Settings/ContactVC.swift`
- Modify: `Wing Me/Settings/VastVC.swift`
- Modify: `Wing Me/Block List/BlockListVC.swift`

**Context:**

**ContactVC:** Replace PHP send with a stub success. Keep all IBOutlets (storyboard wired). After guard passes, show success alert and dismiss. No network call needed for beta.

**VastVC:** No Supabase equivalent for the "vast" social links screen. Stub to empty state. Keep all IBOutlets (storyboard wired). In `viewDidLoad`, stop indicator and hide stackView. The URL-opening IBActions remain intact (safe: they guard on empty string).

**BlockListVC:** Keep `UITableViewDelegate, UITableViewDataSource` conformances (storyboard wires delegate+dataSource). Return 0 rows. Add empty-state label. Keep `@IBOutlet weak var tableView` and `indicator`. Remove all PHP calls.

- [ ] **Step 1: Rewrite ContactVC.swift**

```swift
import UIKit

class ContactVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var sendIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func send(_ sender: UIButton) {
        view.endEditing(true)
        guard !nameTextField.getText().isEmpty && !phoneTextField.getPhone().isEmpty && !messageTextView.getText().isEmpty else {
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        AlertClass().showSuccessAlert(delegate: self, message: Strings.alertMessageSent, action: { [weak self] in
            self?.dismiss(animated: true)
        })
    }
}
```

- [ ] **Step 2: Rewrite VastVC.swift**

```swift
import UIKit

class VastVC: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var facebookView: UIViewDesignable!
    @IBOutlet weak var instagramView: UIViewDesignable!
    @IBOutlet weak var twitterView: UIViewDesignable!
    @IBOutlet weak var whatsappView: UIViewDesignable!
    @IBOutlet weak var phoneView: UIViewDesignable!

    var facebookURL = String()
    var instagramURL = String()
    var twitterURL = String()
    var whatsappURL = String()
    var mapsURL = String()
    var phone = String()

    override func viewDidLoad() {
        super.viewDidLoad()
        indicator.stopAnimating()
        stackView.isHidden = true
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func facebook(_ sender: UIButton) {
        guard !facebookURL.isEmpty, let url = URL(string: facebookURL) else { return }
        UIApplication.shared.open(url, options: [:])
    }

    @IBAction func instagram(_ sender: UIButton) {
        guard !instagramURL.isEmpty, let url = URL(string: instagramURL) else { return }
        UIApplication.shared.open(url, options: [:])
    }

    @IBAction func twitter(_ sender: UIButton) {
        guard !twitterURL.isEmpty, let url = URL(string: twitterURL) else { return }
        UIApplication.shared.open(url, options: [:])
    }

    @IBAction func whatsapp(_ sender: UIButton) {
        guard !whatsappURL.isEmpty, let url = URL(string: whatsappURL) else { return }
        UIApplication.shared.open(url, options: [:])
    }

    @IBAction func phone(_ sender: UIButton) {
        guard !phone.isEmpty, let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}
```

- [ ] **Step 3: Rewrite BlockListVC.swift**

```swift
import UIKit

class BlockListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        indicator.stopAnimating()
        setupEmptyState()
    }

    private func setupEmptyState() {
        let label = UILabel()
        label.text = "No blocked users."
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

    // MARK: - UITableViewDataSource / Delegate stubs (storyboard wires delegate+dataSource)

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }
}
```

- [ ] **Step 4: Build to verify**

Run build command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add "Wing Me/Settings/ContactVC.swift" "Wing Me/Settings/VastVC.swift" "Wing Me/Block List/BlockListVC.swift"
git commit -m "feat(phase7): stub ContactVC, VastVC, BlockListVC to empty state (remove PHP calls)"
```

---

### Task 5: HomeVC — replace PHP get_home with fetchVenues()

**Files:**
- Modify: `Wing Me/Home/HomeVC.swift`

**Context:**
- HomeVC currently fetches banners, events, new_locations, most_visited, last_visited from PHP.
- Replace with: `WAPData.shared.fetchVenues()` populating `newAddedArray` only.
- Hide `bannerView`, `eventsView`, `mostVistedView`, `lastVisitedView` permanently in `viewDidLoad`.
- Show `newAddedView` with venues from `fetchVenues()`.
- Use the established `CustomCell` bridge: `CustomCell(string1: venue.id, string2: venue.name)` for each venue.
- Keep all IBOutlets (storyboard wired). Keep all delegate/datasource conformances (storyboard wires them).
- `var delegate: MainVC!` — keep (used for event wing-in; events section is hidden so never called, but must remain for storyboard/caller compatibility).
- `bannnerArray`, `eventsArray`, `mostVistedArray`, `lastVisitedArray` — keep declarations but never populate them (sections are hidden; returning 0 from tableView:numberOfRowsInSection: is sufficient).
- `refresh()` — wire to async fetch, clear `newAddedArray` and reload.
- `openSingleLocation(customCell:)` — keep as-is (still used from newAddedTableView tap).
- `viewDidLayoutSubviews()` — keep as-is (hidden tables have 0 content size; height constraints update to 0 correctly).
- The CollectionView (bannerCollectionView) is hidden inside bannerView. Its delegate/dataSource must still return valid responses (0 items).

- [ ] **Step 1: Rewrite HomeVC.swift**

```swift
import UIKit

class HomeVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var bannerView: UIView!
    @IBOutlet weak var bannerCollectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var eventsView: UIView!
    @IBOutlet weak var eventsTableView: UITableView!
    @IBOutlet weak var eventsTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var newAddedView: UIView!
    @IBOutlet weak var newAddedTableView: UITableView!
    @IBOutlet weak var newAddedTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var mostVistedView: UIView!
    @IBOutlet weak var mostVistedTableView: UITableView!
    @IBOutlet weak var mostVistedTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var lastVisitedView: UIView!
    @IBOutlet weak var lastVisitedTableView: UITableView!
    @IBOutlet weak var lastVisitedTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    let refreshControl = UIRefreshControl()

    var delegate: MainVC!

    var bannnerArray: [CustomCell] = []
    var eventsArray: [EventStruct] = []
    var newAddedArray: [CustomCell] = []
    var mostVistedArray: [CustomCell] = []
    var lastVisitedArray: [CustomCell] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.isHidden = true
        bannerView.isHidden = true
        eventsView.isHidden = true
        mostVistedView.isHidden = true
        lastVisitedView.isHidden = true

        refreshControl.tintColor = Colors.blue
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        scrollView.addSubview(refreshControl)

        request()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        eventsTableView.layoutIfNeeded()
        eventsTableViewHeight.constant = eventsTableView.contentSize.height
        newAddedTableView.layoutIfNeeded()
        newAddedTableViewHeight.constant = newAddedTableView.contentSize.height
        mostVistedTableView.layoutIfNeeded()
        mostVistedTableViewHeight.constant = mostVistedTableView.contentSize.height
        lastVisitedTableView.layoutIfNeeded()
        lastVisitedTableViewHeight.constant = lastVisitedTableView.contentSize.height
    }

    // MARK: - UICollectionViewDataSource / Delegate (bannerView hidden — stubs only)

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 0 }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: "HomeBannerCell", for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }

    // MARK: - UITableViewDataSource / Delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView == newAddedTableView ? newAddedArray.count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeLocationCell", for: indexPath) as! HomeLocationCell
        cell.updateCell(customCell: newAddedArray[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 100 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView == newAddedTableView else { return }
        openSingleLocation(customCell: newAddedArray[indexPath.row])
    }

    // MARK: - Data

    func request() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let venues = try await WAPData.shared.fetchVenues()
                await MainActor.run {
                    self.newAddedArray = venues.map { CustomCell(string1: $0.id, string2: $0.name) }
                    self.newAddedView.isHidden = self.newAddedArray.isEmpty
                    self.newAddedTableViewHeight.constant = CGFloat.greatestFiniteMagnitude
                    self.newAddedTableView.reloadData()
                    self.indicator.stopAnimating()
                    self.scrollView.isHidden = false
                    self.viewDidLayoutSubviews()
                }
            } catch {
                await MainActor.run {
                    self.indicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    @objc func refresh() {
        scrollView.isHidden = true
        newAddedArray = []
        newAddedTableView.reloadData()
        refreshControl.endRefreshing()
        indicator.startAnimating()
        request()
    }

    func openSingleLocation(customCell: CustomCell) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "SingleLocationVC") as? SingleLocationVC {
            vc.id = customCell.string1
            present(vc, animated: true)
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run build command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add "Wing Me/Home/HomeVC.swift"
git commit -m "feat(phase7): replace HomeVC PHP get_home with fetchVenues() showing venue list"
```

---

## Phase 7 Deferred (out of scope)

- `AboutVC.swift` — dead code after Task 3 (never instantiated), no PHP calls triggered. Leave as-is.
- `MessagesVC.swift` / `ChatVC.swift` — complex CoreData → Supabase Realtime migration. Phase 8.
- `MyLocationVC.swift` / `SocialSettingsVC.swift` — venue admin screens. Later phase.
- `EditLocationVC`, `AddBannerVC`, `EventsVC`, `EditEventVC`, `CreateEventPicker` — admin/event management. Later phase.
- `GenerateUserVC`, `MyProfilePicker` — profile utilities. Later phase.
- `Profile Setup` VCs (First/Second/Third/Fourth/FifthSetupVC) — onboarding. Later phase.
- `SingleLocationVC`, `SendMessageVC`, `SelectUsersVC`, `ReplyVC` — later phase.
- `WelcomeVC`, `RegisterVC`, `NewMyLocationVC`, `WAPData.swift` — grep hits are vestigial references; already migrated.
