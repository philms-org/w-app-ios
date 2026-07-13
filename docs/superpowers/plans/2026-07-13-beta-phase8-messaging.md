# Beta Phase 8 — Messaging Stubs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stub all messaging-related VCs to empty state, removing CoreData and PHP backend calls, while preserving all storyboard IBOutlet/IBAction connections to prevent KVC crashes.

**Architecture:** Same pattern as Phase 6/7 stubs — keep all `@IBOutlet`/`@IBAction` declarations verbatim, strip CoreData (`Message` entity, `context.fetch`) and PHP (`NSDictionary.request`), return 0 rows from TableView stubs, show empty/coming-soon state.

**Tech Stack:** UIKit, Swift. No Supabase calls in this phase — pure stub/empty-state work.

## Global Constraints

- ALL `@IBOutlet` and `@IBAction` declarations must be preserved exactly as they appear in the original file
- `var messagesID: [Message] = []` must be removed from MessagesVC and ChatVC/GroupChatVC
- No `context.fetch(...)` calls anywhere in stubbed files
- No `NSDictionary.request(...)` calls anywhere in stubbed files
- No force-unwraps in new code
- `[weak self]` in all Task closures and UIAlertAction handlers
- Build command: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS" build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -4`

---

### Task 1: MessagesVC — strip CoreData + PHP, show empty state

**Files:**
- Modify: `Wing Me/Messages/MessagesVC.swift`

**IBOutlets to keep:** `messagesTableView`, `groupsTableView`, `noMessagesView`, `indicator`

**IBActions to keep:** `sort(_ sender: UIButton)`, `selectTab(_ sender: UIButton)`, `shareApp(_ sender: UIButton)`

**@objc to keep:** `refreshMessages()`, `refreshGroups()`

**What to remove:**
- `var messagesID: [Message] = []`
- All `context.fetch(Message.fetchRequest())` calls
- All `appDelegate.setLastMessage/setLastGroupMessage/reloadMessages/reloadGroups/setInbox/setGroup` closures
- `getInbox/inboxStopLoading/inboxSuccess`, `getGroups/groupsStopLoading/groupsSuccess`
- `delete/deleteStopLoading/deleteSuccess`, `deleteChat`
- `checkBadge`, `setInbox`, `setGroup`, `reloadMessages`, `reloadGroups`, `getTime`

**Resulting viewDidLoad:**
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    noMessagesView.isHidden = true
    setKeyboard()
    messagesRefreshControl.tintColor = Colors.blue
    messagesRefreshControl.addTarget(self, action: #selector(refreshMessages), for: .valueChanged)
    messagesTableView.addSubview(messagesRefreshControl)
    groupsRefreshControl.tintColor = Colors.blue
    groupsRefreshControl.addTarget(self, action: #selector(refreshGroups), for: .valueChanged)
    groupsTableView.addSubview(groupsRefreshControl)
    setTab(tag: 11)
    indicator.stopAnimating()
}
```

**@objc stubs:**
```swift
@objc func refreshMessages() { messagesRefreshControl.endRefreshing() }
@objc func refreshGroups() { groupsRefreshControl.endRefreshing() }
```

**TableView stubs:**
```swift
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }
func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { nil }
```

**Preserve:** `var delegate: MainVC!`, `var lastTag = 12`, `let messagesRefreshControl/groupsRefreshControl`, `var messagesArray/groupsArray: [CustomCell] = []`, `setTab(tag:)`, all three IBActions.

- [ ] Write MessagesVC.swift
- [ ] Verify: grep confirms no `Message`, no `context`, no `.request(`
- [ ] Run build — must show BUILD SUCCEEDED
- [ ] Commit

---

### Task 2: ChatVC — strip CoreData + PHP

**Files:**
- Modify: `Wing Me/Chat/ChatVC.swift`

**IBOutlets to keep (all storyboard wired):**
`menuButton`, `genderView`, `imageView`, `nameLabel`, `checkmarkImageView`, `detailsLabel`, `tableView`, `indicator`, `stackView`, `messageView`, `textFieldView`, `messageTextView`, `messageLabel`, `sendButton`, `sendIndicator`, `acceptView`, `rejectButton`, `rejectIndicator`, `acceptButton`, `acceptIndicator`

**IBActions to keep:** `back(_:)`, `menu(_:)`, `viewImage(_:)`, `send(_:)`, `accept(_:)`

**@objc to keep:** `KeyboardWillShow(notification:)`, `KeyboardWillHide(notification:)`

**Properties to keep:** `var close: (() -> ())?`, `var id = String()`, `var gender = String()`, `var blocked = String()`, `var keyboardHeight = CGFloat()`

**What to remove:** `var messagesID: [Message] = []`, `var array: [CustomCell] = []`, `var lastDate = String()`, all CoreData fetches, `appDelegate.userID = id`, `appDelegate.reloadChat` closure, `request()` and all PHP methods, `textViewDidChange(_:)`, `numberOfSections(in:)`

**Resulting viewDidLoad:**
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    setKeyboard(tableView: tableView)
    checkmarkImageView.isHidden = true
    messageView.isHidden = true
    acceptView.isHidden = true
    nameLabel.text = ""
    detailsLabel.text = ""
    indicator.stopAnimating()
    NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
}
```

**IBActions:** `back` → `close?()`, others → empty body.

**TableView stubs:** numberOfRowsInSection → 0, cellForRowAt → UITableViewCell().

- [ ] Write ChatVC.swift
- [ ] Verify: no `Message`, no `context`, no `.request(`
- [ ] Run build
- [ ] Commit

---

### Task 3: GroupChatVC — strip CoreData + PHP

**Files:**
- Modify: `Wing Me/Group Chat/GroupChatVC.swift`

**IBOutlets to keep:** `menuButton`, `imageView`, `nameLabel`, `tableView`, `indicator`, `stackView`, `messageView`, `messageTextView`, `messageLabel`, `sendButton`, `sendIndicator`

**IBActions to keep:** `back(_:)`, `menu(_:)`, `viewImage(_:)`, `send(_:)`

**@objc to keep:** `KeyboardWillShow(notification:)`, `KeyboardWillHide(notification:)`

**Properties to keep:** `var close: (() -> ())?`, `var id = String()`, `var titleString = String()`, `var isAdmin = Bool()`, `var isMute = Bool()`, `var keyboardHeight = CGFloat()`

**What to remove:** `var messagesID: [Message] = []`, `var array: [CustomCell] = []`, `var lastDate = String()`, all CoreData fetches, `appDelegate.groupID = id`, `appDelegate.reloadGroup` closure, `request()` and all PHP methods, `textViewDidChange(_:)`, `numberOfSections(in:)`

**viewDidLoad:**
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    setKeyboard(tableView: tableView)
    messageView.isHidden = true
    nameLabel.text = ""
    indicator.stopAnimating()
    NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
}
```

**IBActions:** `back` → `close?()`, others → empty body.

**TableView stubs:** numberOfRowsInSection → 0, cellForRowAt → UITableViewCell().

- [ ] Write GroupChatVC.swift
- [ ] Verify: no `Message`, no `context`, no `.request(`
- [ ] Run build
- [ ] Commit

---

### Task 4: GroupMembersVC — strip PHP, empty table

**Files:**
- Modify: `Wing Me/Group Chat/GroupMembersVC.swift`

**IBOutlets to keep:** `tableView`, `indicator`

**IBActions to keep:** `back(_ sender: UIButton)`

**Properties to keep:** `var groupID = String()`, `var isAdmin = Bool()`

**What to remove:** `var array: [CustomCell] = []`, `request()`, `stopLoading()`, `requestSuccess()`, `removeMember()`, `removeStopLoading()`, `removeSuccess()`, `reload()`

**viewDidLoad:**
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    indicator.stopAnimating()
}
```

**TableView stubs:**
```swift
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }
func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { nil }
```

- [ ] Write GroupMembersVC.swift
- [ ] Verify: no `.request(`
- [ ] Run build
- [ ] Commit

---

### Task 5: SendMessageVC + SelectUsersVC — strip PHP, stub UI

**Files:**
- Modify: `Wing Me/Send Message/SendMessageVC.swift`
- Modify: `Wing Me/Send Message/SelectUsersVC.swift`

#### SendMessageVC:
**IBOutlets:** `messageTextView`, `sendButton`, `sendIndicator`
**IBActions:** `back(_ sender: UIButton)`, `send(_ sender: UIButton)`
**Property:** `var usersArray: [UserClass] = []`

**Remove:** `send()` private PHP func, `sendStopLoading()`, `sendSuccess()`, `getUsers()`

**send IBAction:**
```swift
@IBAction func send(_ sender: UIButton) {
    view.endEditing(true)
    guard !messageTextView.getText().isEmpty else {
        AlertClass().showWarningAlert(delegate: self, message: Strings.alertEmpty)
        return
    }
    AlertClass().showSuccessAlert(delegate: self, message: Strings.alertMessageSent) { [weak self] in
        self?.dismiss(animated: true)
    }
}
```

#### SelectUsersVC:
**IBOutlets:** `searchTextField`, `allLabel`, `allSelectedView`, `tableView`, `sendButton`, `indicator`
**IBActions:** `back(_:)`, `editingChanged(_:)`, `filter(_:)`, `selectAllUsers(_:)`, `sendMessage(_:)`
**Properties:** `var allArray: [UserClass] = []`, `var usersArray: [UserClass] = []`, `var allSelected = Bool()`, `var isMaster = Bool()`, `var isOwner = Bool()`

**Remove:** `var countiresArray/citiesArray/countrySelected/citySelected/lastGender`, `request()`, `stopLoading()`, `requestSuccess()`, `filter(countrySelected:citySelected:lastGender:)` func

**viewDidLoad:**
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    allSelectedView.isHidden = true
    sendButton.isEnabled = false
    setKeyboard()
    indicator.stopAnimating()
}
```

**filter IBAction:** `@IBAction func filter(_ sender: UIButton) { }` (no-op — FilterVC references removed state)

**editingChanged, selectAllUsers, sendMessage, updateUI:** keep as-is (operate on empty arrays harmlessly).

**TableView stubs:**
```swift
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { tableView.deselectRow(at: indexPath, animated: true) }
```

- [ ] Write SendMessageVC.swift
- [ ] Write SelectUsersVC.swift
- [ ] Verify: no `.request(` in either file
- [ ] Run build
- [ ] Commit both

---

### Task 6: ReplyVC — strip PHP, stub comments, keep setUI()

**Files:**
- Modify: `Wing Me/New My Location/ReplyVC.swift`

**IBOutlets to keep:** `genderView`, `userImageView`, `nameLabel`, `detailsLabel`, `commentLabel`, `likeButton`, `likesLabel`, `indicator`, `commentsTableView`, `commentView`, `commentTextField`, `sendButton`, `sendIndicator`

**IBActions to keep:** `send(_ sender: UIButton)`

**@objc to keep:** `KeyboardWillShow(notification:)`, `KeyboardWillHide(notification:)`

**Properties to keep:** `var commentsArray: [CommentStruct] = []`, `var comment: CommentStruct!`, `var locationID = String()`, `var isMaster = Bool()`, `var isOwner = Bool()`

**ReplyDelegate conformance (required by protocol in ReplyCell.swift):**
```swift
func openProfile(cell: UITableViewCell) { }
func like(cell: UITableViewCell) { }
func add(cell: UITableViewCell) { }
```

**Keep `setUI()`** — no network calls, reads from `comment: CommentStruct!` passed by caller.

**What to remove:** `request()`, `reload()`, `requestSuccess()`, `stopLoading()`, `addComment/addCommentStopLoading/addCommentSuccess`, `addLike/addLikeStopLoading/addLikeSuccess`, `deleteLike/deleteLikeStopLoading/deleteLikeSuccess`, `deleteComment/deleteCommentStopLoading/deleteCommentSuccess`, `addUserGroup/addUserGroupStopLoading/addUserGroupSuccess`, `deleteUserGroup/deleteUserGroupStopLoading/deleteUserGroupSuccess`, `assignBadge/assignBadgeStopLoading/assignBadgeSuccess`, `removeBadge/removeBadgeStopLoading/removeBadgeSuccess`, `openBadges(item:)`

**Resulting viewDidLoad:**
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    setKeyboard()
    setUI()
    indicator.stopAnimating()
}
```

**send IBAction:** `@IBAction func send(_ sender: UIButton) { }`

**TableView stubs:**
```swift
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }
func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { nil }
```

- [ ] Write ReplyVC.swift
- [ ] Verify: no `.request(` in the file
- [ ] Run build — must show BUILD SUCCEEDED
- [ ] Commit
