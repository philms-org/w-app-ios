# Beta Phase 14 — Messaging (1:1 + Group) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Wire `MessagesVC`, `ChatVC`, `GroupChatVC`, `GroupMembersVC`, `SelectUsersVC`, `SendMessageVC` (all empty-state stubs since Phase 8) to a new Supabase-backed messaging system, per `docs/superpowers/specs/2026-07-16-beta-phase14-messaging-design.md`.

**Architecture:** Task 1 adds the schema (new tables, no prior migration touches messaging) and the matching Swift models. Task 2 adds the `WAPData` data-layer functions every screen calls. Tasks 3–6 wire each screen, preserving every existing `@IBOutlet`/`@IBAction`.

**Tech Stack:** Swift 5, UIKit, Supabase Swift SDK.

## Global Constraints

- Open `The W App.xcworkspace`, never `.xcodeproj`.
- Verify each task with a full build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build` from `/Users/sr/W-legacy-repo`.
- No functional XCTest target exists (known, pre-existing) — verification is build-only.
- No force-unwraps. `[weak self]` in every closure/`Task`. Follow the existing `WAPData` pattern exactly: `client.from("table").select("*, profiles(*)")...`, `async throws`, caller wraps in `Task { do { ... } catch { AlertClass().showErrorAlert(...) } }`.
- Do not touch `ReplyVC` — feed-comment replies are a separate, already-partially-wired subsystem, explicitly out of scope.
- Migration file is written and committed but **not** applied automatically — user runs it in the Supabase SQL Editor (same convention as every prior migration in this project).

---

### Task 1: Migration + models

**Files:**
- Create: `database/migrations/012_messaging.sql`
- Modify: `The W App/Classes/WAPModels.swift` (append `WAPConversation`, `WAPMessage`)

**Interfaces:**
- Produces: `WAPConversation` (id, isGroup, name, lastMessage, lastMessageAt, myStatus, otherProfile), `WAPMessage` (id, conversationId, senderId, content, createdAt, profile) — both `Codable, Identifiable`, snake_case `CodingKeys` matching the tables below.

- [ ] **Step 1: Write the migration**

```sql
-- 012_messaging.sql
create table conversations (
  id uuid primary key default uuid_generate_v4(),
  is_group boolean not null default false,
  name text,
  created_by uuid references profiles(id) on delete cascade,
  created_at timestamptz default now()
);

create table conversation_participants (
  conversation_id uuid references conversations(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  status text not null check (status in ('pending', 'accepted', 'rejected')) default 'accepted',
  joined_at timestamptz default now(),
  primary key (conversation_id, user_id)
);

create table messages (
  id uuid primary key default uuid_generate_v4(),
  conversation_id uuid references conversations(id) on delete cascade,
  sender_id uuid references profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz default now()
);

alter table conversations enable row level security;
alter table conversation_participants enable row level security;
alter table messages enable row level security;

create policy conversations_select on conversations for select
  using (exists (
    select 1 from conversation_participants cp
    where cp.conversation_id = conversations.id and cp.user_id = auth.uid()
  ));

create policy conversations_insert on conversations for insert
  with check (created_by = auth.uid());

create policy participants_select on conversation_participants for select
  using (exists (
    select 1 from conversation_participants cp2
    where cp2.conversation_id = conversation_participants.conversation_id and cp2.user_id = auth.uid()
  ));

create policy participants_insert on conversation_participants for insert
  with check (exists (
    select 1 from conversations c
    where c.id = conversation_participants.conversation_id and c.created_by = auth.uid()
  ) or user_id = auth.uid());

create policy participants_update_own on conversation_participants for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy messages_select on messages for select
  using (exists (
    select 1 from conversation_participants cp
    where cp.conversation_id = messages.conversation_id and cp.user_id = auth.uid()
  ));

create policy messages_insert on messages for insert
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from conversation_participants cp
      where cp.conversation_id = messages.conversation_id
        and cp.user_id = auth.uid()
        and cp.status = 'accepted'
    )
  );
```

- [ ] **Step 2: Add the models**

Append to `The W App/Classes/WAPModels.swift`:

```swift
struct WAPConversation: Codable, Identifiable {
    let id: String
    var isGroup: Bool
    var name: String?
    var lastMessage: String?
    var lastMessageAt: String?
    var myStatus: String
    var otherProfile: WAPProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case isGroup       = "is_group"
        case name
        case lastMessage   = "last_message"
        case lastMessageAt = "last_message_at"
        case myStatus      = "my_status"
        case otherProfile  = "other_profile"
    }
}

struct WAPMessage: Codable, Identifiable {
    let id: String
    let conversationId: String
    let senderId: String
    var content: String
    var createdAt: String
    var profile: WAPProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId       = "sender_id"
        case content
        case createdAt      = "created_at"
        case profile        = "profiles"
    }
}
```

Note: `lastMessage`/`lastMessageAt`/`myStatus`/`otherProfile` aren't real columns — `fetchConversations()` (Task 2) builds these client-side per conversation, not via a direct table select, so `WAPConversation` is never round-tripped through `.select().value` directly. It's still `Codable` for consistency with every other model in this file, but Task 2 constructs instances manually.

- [ ] **Step 3: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
cd /Users/sr/W-legacy-repo
git add database/migrations/012_messaging.sql "The W App/Classes/WAPModels.swift"
git commit -m "feat(phase14): add messaging schema and WAPConversation/WAPMessage models"
```

---

### Task 2: WAPData messaging functions

**Files:**
- Modify: `The W App/Classes/WAPData.swift` (append a `// MARK: - Messaging` section)

**Interfaces:**
- Consumes: `WAPConversation`, `WAPMessage` (Task 1), `WAPAuth.currentUserID` (existing), `client` (existing `private var client: SupabaseClient`).
- Produces: `fetchConversations() async throws -> [WAPConversation]`, `fetchMessages(conversationId: String) async throws -> [WAPMessage]`, `sendMessage(conversationId: String, content: String) async throws`, `startConversation(recipientIds: [String], name: String?, isGroup: Bool, firstMessage: String) async throws -> WAPConversation`, `respondToConversationRequest(conversationId: String, accept: Bool) async throws`, `fetchGroupMembers(conversationId: String) async throws -> [WAPProfile]`.

- [ ] **Step 1: Append the messaging functions**

```swift
    // MARK: - Messaging

    private struct ParticipantRow: Codable {
        let conversationId: String
        let status: String
        let conversation: ConversationRow

        enum CodingKeys: String, CodingKey {
            case conversationId = "conversation_id"
            case status
            case conversation = "conversations"
        }
    }

    private struct ConversationRow: Codable {
        let id: String
        let isGroup: Bool
        let name: String?

        enum CodingKeys: String, CodingKey {
            case id
            case isGroup = "is_group"
            case name
        }
    }

    func fetchConversations() async throws -> [WAPConversation] {
        guard let uid = WAPAuth.currentUserID else { return [] }

        let rows: [ParticipantRow] = try await client
            .from("conversation_participants")
            .select("conversation_id, status, conversations(id, is_group, name)")
            .eq("user_id", value: uid)
            .execute()
            .value

        var result: [WAPConversation] = []
        for row in rows {
            let recent: [WAPMessage] = try await client
                .from("messages")
                .select()
                .eq("conversation_id", value: row.conversationId)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            var otherProfile: WAPProfile?
            if !row.conversation.isGroup {
                let others: [ParticipantProfileRow] = try await client
                    .from("conversation_participants")
                    .select("user_id, profiles(*)")
                    .eq("conversation_id", value: row.conversationId)
                    .neq("user_id", value: uid)
                    .limit(1)
                    .execute()
                    .value
                otherProfile = others.first?.profile
            }

            result.append(WAPConversation(
                id: row.conversationId,
                isGroup: row.conversation.isGroup,
                name: row.conversation.name,
                lastMessage: recent.first?.content,
                lastMessageAt: recent.first?.createdAt,
                myStatus: row.status,
                otherProfile: otherProfile
            ))
        }
        return result
    }

    private struct ParticipantProfileRow: Codable {
        let userId: String
        let profile: WAPProfile?

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case profile = "profiles"
        }
    }

    func fetchMessages(conversationId: String) async throws -> [WAPMessage] {
        try await client
            .from("messages")
            .select("*, profiles(*)")
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func sendMessage(conversationId: String, content: String) async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        struct NewMessage: Encodable {
            let conversation_id: String
            let sender_id: String
            let content: String
        }
        try await client
            .from("messages")
            .insert(NewMessage(conversation_id: conversationId, sender_id: uid, content: content))
            .execute()
    }

    func startConversation(recipientIds: [String], name: String?, isGroup: Bool, firstMessage: String) async throws -> WAPConversation {
        guard let uid = WAPAuth.currentUserID else {
            throw NSError(domain: "WAPData", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }

        struct NewConversation: Encodable {
            let is_group: Bool
            let name: String?
            let created_by: String
        }
        let created: ConversationRow = try await client
            .from("conversations")
            .insert(NewConversation(is_group: isGroup, name: name, created_by: uid))
            .select()
            .single()
            .execute()
            .value

        struct NewParticipant: Encodable {
            let conversation_id: String
            let user_id: String
            let status: String
        }

        var alreadyFriends: Set<String> = []
        if !isGroup {
            let friendRows: [FriendshipRow] = try await client
                .from("friendships")
                .select("friend_id")
                .eq("user_id", value: uid)
                .in("friend_id", values: recipientIds)
                .execute()
                .value
            alreadyFriends = Set(friendRows.map { $0.friendId })
        }

        var participants = [NewParticipant(conversation_id: created.id, user_id: uid, status: "accepted")]
        for recipientId in recipientIds {
            let status = isGroup ? "accepted" : (alreadyFriends.contains(recipientId) ? "accepted" : "pending")
            participants.append(NewParticipant(conversation_id: created.id, user_id: recipientId, status: status))
        }
        try await client
            .from("conversation_participants")
            .insert(participants)
            .execute()

        try await sendMessage(conversationId: created.id, content: firstMessage)

        return WAPConversation(
            id: created.id,
            isGroup: created.isGroup,
            name: created.name,
            lastMessage: firstMessage,
            lastMessageAt: nil,
            myStatus: "accepted",
            otherProfile: nil
        )
    }

    private struct FriendshipRow: Codable {
        let friendId: String
        enum CodingKeys: String, CodingKey { case friendId = "friend_id" }
    }

    func respondToConversationRequest(conversationId: String, accept: Bool) async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        try await client
            .from("conversation_participants")
            .update(["status": accept ? "accepted" : "rejected"])
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: uid)
            .execute()
    }

    func fetchGroupMembers(conversationId: String) async throws -> [WAPProfile] {
        let rows: [ParticipantProfileRow] = try await client
            .from("conversation_participants")
            .select("user_id, profiles(*)")
            .eq("conversation_id", value: conversationId)
            .execute()
            .value
        return rows.compactMap { $0.profile }
    }
```

Note on `startConversation`: the `.insert(...).select().single()` pattern for getting the created row back needs a quick sanity check before implementing — run `grep -n "\.insert(" -A 3 "The W App/Classes/WAPData.swift"` to see whether any existing function already does an insert-then-select-single round trip; if the installed Supabase SDK version needs that split differently, adjust to match whatever pattern is already proven to compile elsewhere in this file.

- [ ] **Step 2: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
cd /Users/sr/W-legacy-repo
git add "The W App/Classes/WAPData.swift"
git commit -m "feat(phase14): add WAPData messaging functions"
```

---

### Task 3: Wire MessagesVC

**Files:**
- Modify: `The W App/Messages/MessagesVC.swift`

**Interfaces:**
- Consumes: `WAPData.shared.fetchConversations()` (Task 2), `WAPConversation` (Task 1).

- [ ] **Step 1: Replace `viewDidLoad`/stubs with real loading**

```swift
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    func reload() {
        indicator.startAnimating()
        Task {
            do {
                let conversations = try await WAPData.shared.fetchConversations()
                await MainActor.run {
                    self.messagesArray = conversations.filter { !$0.isGroup }.map(self.toCell)
                    self.groupsArray = conversations.filter { $0.isGroup }.map(self.toCell)
                    self.messagesTableView.reloadData()
                    self.groupsTableView.reloadData()
                    self.noMessagesView.isHidden = !(self.lastTag == 11 ? self.messagesArray.isEmpty : self.groupsArray.isEmpty)
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

    func toCell(_ conversation: WAPConversation) -> CustomCell {
        let imageView = UIImageView()
        if let avatarURL = conversation.otherProfile?.avatarURL, !avatarURL.isEmpty {
            imageView.imageFromServerURL(urlString: avatarURL, tableView: messagesTableView)
        }
        let name = conversation.isGroup ? (conversation.name ?? "Group") : (conversation.otherProfile?.displayName ?? "")
        let statusLabel = conversation.myStatus == "pending" ? "Request" : ""
        return CustomCell(imageView: imageView,
                          string1: conversation.id,
                          string2: name,
                          string3: conversation.lastMessage ?? "",
                          string4: statusLabel,
                          string5: "",
                          string6: "",
                          string7: "",
                          isMaster: false)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView == messagesTableView ? messagesArray.count : groupsArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = tableView == messagesTableView ? messagesArray[indexPath.row] : groupsArray[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as? MessageCell else {
            assertionFailure("MessagesVC storyboard cell identifier drifted from \"MessageCell\"")
            return UITableViewCell()
        }
        cell.configure(item: item)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = tableView == messagesTableView ? messagesArray[indexPath.row] : groupsArray[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if tableView == messagesTableView, let vc = storyboard.instantiateViewController(withIdentifier: "ChatVC") as? ChatVC {
            vc.id = item.string1
            navigationController?.pushViewController(vc, animated: true)
        } else if let vc = storyboard.instantiateViewController(withIdentifier: "GroupChatVC") as? GroupChatVC {
            vc.id = item.string1
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc func refreshMessages() {
        reload()
        messagesRefreshControl.endRefreshing()
    }

    @objc func refreshGroups() {
        reload()
        groupsRefreshControl.endRefreshing()
    }
```

This replaces the file's existing three-line `tableView(_:numberOfRowsInSection:)` / `tableView(_:cellForRowAt:)` stub pair and the two `refreshMessages`/`refreshGroups` stub bodies; `trailingSwipeActionsConfigurationForRowAt:` stays unchanged (still correctly returns `nil`).

Before finalizing, run `grep -n "class MessageCell" -A 15 "The W App/Messages/MessageCell.swift"` to confirm its actual `configure(item:)` method name/signature (this plan assumes the same `configure(item: CustomCell)` convention other list cells in this codebase use, e.g. `LocationPersonCell`, but `MessageCell.swift` itself wasn't read while writing this plan) and adjust if it's drifted. If `configure(item:)` doesn't exist yet, add it following whatever label/image structure `MessageCell` already declares as `@IBOutlet`s.

- [ ] **Step 2: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
cd /Users/sr/W-legacy-repo
git add "The W App/Messages/MessagesVC.swift"
git commit -m "feat(phase14): wire MessagesVC to WAPData.fetchConversations"
```

---

### Task 4: Wire ChatVC

**Files:**
- Modify: `The W App/Chat/ChatVC.swift`

**Interfaces:**
- Consumes: `WAPData.shared.fetchMessages(conversationId:)`, `.sendMessage(conversationId:content:)`, `.respondToConversationRequest(conversationId:accept:)` (Task 2), `WAPMessage` (Task 1), `WAPAuth.currentUserID` (existing).

- [ ] **Step 1: Add message state, load, send, accept/reject**

Add below the existing `var blocked = String()` line:

```swift
    var messagesArray: [WAPMessage] = []
    var myStatus = "accepted"
```

Replace `viewDidLoad` and the empty `send`/`accept` `@IBAction` bodies:

```swift
    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard(tableView: tableView)
        checkmarkImageView.isHidden = true
        messageView.isHidden = true
        acceptView.isHidden = true
        nameLabel.text = ""
        detailsLabel.text = ""
        genderView.isHidden = true
        indicator.startAnimating()

        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        reload()
    }

    func reload() {
        Task {
            do {
                let messages = try await WAPData.shared.fetchMessages(conversationId: id)
                await MainActor.run {
                    self.messagesArray = messages
                    if let first = messages.first(where: { $0.senderId != WAPAuth.currentUserID }) {
                        self.nameLabel.text = first.profile?.displayName ?? ""
                    }
                    self.tableView.reloadData()
                    self.indicator.stopAnimating()
                    self.updateRequestUI()
                }
            } catch {
                await MainActor.run {
                    self.indicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    func updateRequestUI() {
        let isPendingRecipient = myStatus == "pending"
        acceptView.isHidden = !isPendingRecipient
        messageView.isHidden = isPendingRecipient
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messagesArray.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messagesArray[indexPath.row]
        let isMine = message.senderId == WAPAuth.currentUserID
        let identifier = isMine ? "ChatRightCell" : "ChatLeftCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ChatMessageCell else {
            assertionFailure("ChatVC storyboard cell identifiers drifted from \"ChatLeftCell\"/\"ChatRightCell\"")
            return UITableViewCell()
        }
        cell.configure(message: message)
        return cell
    }

    @IBAction func send(_ sender: UIButton) {
        let text = messageTextView.getText()
        guard !text.isEmpty else { return }
        sendButton.isHidden = true
        sendIndicator.startAnimating()
        Task {
            do {
                try await WAPData.shared.sendMessage(conversationId: id, content: text)
                await MainActor.run {
                    self.messageTextView.text = ""
                    self.sendButton.isHidden = false
                    self.sendIndicator.stopAnimating()
                    self.reload()
                }
            } catch {
                await MainActor.run {
                    self.sendButton.isHidden = false
                    self.sendIndicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    @IBAction func accept(_ sender: UIButton) {
        respond(accept: sender === acceptButton)
    }

    func respond(accept: Bool) {
        let indicatorView = accept ? acceptIndicator : rejectIndicator
        indicatorView?.startAnimating()
        Task {
            do {
                try await WAPData.shared.respondToConversationRequest(conversationId: id, accept: accept)
                await MainActor.run {
                    indicatorView?.stopAnimating()
                    self.myStatus = accept ? "accepted" : "rejected"
                    if accept {
                        self.updateRequestUI()
                    } else {
                        self.close?()
                    }
                }
            } catch {
                await MainActor.run {
                    indicatorView?.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }
```

Notes: `genderView`/`checkmarkImageView` are hidden unconditionally rather than deleted (dating-era leftovers, same treatment `UserProfileVC` got in Phase 6) since they're storyboard-connected outlets and removing them risks the KVC crash Phase 2's final review caught. The current stub only has a single `@IBAction func accept` (no separate reject action) — confirm via `grep -n "@IBAction" "The W App/Chat/ChatVC.swift"` and the storyboard connections inspector whether `rejectButton` is wired to this same action or its own; if it has its own, split into `acceptTapped`/`rejectTapped` accordingly. `ChatMessageCell` is assumed as a shared protocol/base both `ChatLeftCell`/`ChatRightCell` conform to — grep `grep -n "class ChatLeftCell\|class ChatRightCell" -A 10 "The W App/Chat/"*.swift` before implementing (these two files weren't read while writing this plan) and add `configure(message: WAPMessage)` to each matching their existing label/bubble structure.

- [ ] **Step 2: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
cd /Users/sr/W-legacy-repo
git add "The W App/Chat/ChatVC.swift"
git commit -m "feat(phase14): wire ChatVC to WAPData messaging + accept/reject requests"
```

---

### Task 5: Wire GroupChatVC + GroupMembersVC

**Files:**
- Modify: `The W App/Group Chat/GroupChatVC.swift`
- Modify: `The W App/Group Chat/GroupMembersVC.swift`

**Interfaces:**
- Consumes: `WAPData.shared.fetchMessages(conversationId:)`, `.sendMessage(conversationId:content:)`, `.fetchGroupMembers(conversationId:)` (Task 2).

- [ ] **Step 1: Wire GroupChatVC**

Add below `var isMute = Bool()`:

```swift
    var messagesArray: [WAPMessage] = []
```

Replace `viewDidLoad` and the stub methods:

```swift
    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard(tableView: tableView)
        messageView.isHidden = false
        nameLabel.text = titleString
        indicator.startAnimating()

        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        reload()
    }

    func reload() {
        Task {
            do {
                let messages = try await WAPData.shared.fetchMessages(conversationId: id)
                await MainActor.run {
                    self.messagesArray = messages
                    self.tableView.reloadData()
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messagesArray.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messagesArray[indexPath.row]
        let isMine = message.senderId == WAPAuth.currentUserID
        let identifier = isMine ? "ChatRightCell" : "ChatLeftCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ChatMessageCell else {
            assertionFailure("GroupChatVC storyboard cell identifiers drifted")
            return UITableViewCell()
        }
        cell.configure(message: message)
        return cell
    }

    @IBAction func menu(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "GroupMembersVC") as? GroupMembersVC {
            vc.groupID = id
            vc.isAdmin = isAdmin
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func send(_ sender: UIButton) {
        let text = messageTextView.getText()
        guard !text.isEmpty else { return }
        sendButton.isHidden = true
        sendIndicator.startAnimating()
        Task {
            do {
                try await WAPData.shared.sendMessage(conversationId: id, content: text)
                await MainActor.run {
                    self.messageTextView.text = ""
                    self.sendButton.isHidden = false
                    self.sendIndicator.stopAnimating()
                    self.reload()
                }
            } catch {
                await MainActor.run {
                    self.sendButton.isHidden = false
                    self.sendIndicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }
```

If `GroupChatVC`'s storyboard uses distinct cell identifiers (e.g. a dedicated `GroupChatCell` instead of reusing `ChatLeftCell`/`ChatRightCell`), grep `grep -n "class GroupChatCell" -A 15 "The W App/Group Chat/GroupChatCell.swift"` and adjust the identifiers/casts above accordingly (this file wasn't read while writing this plan).

- [ ] **Step 2: Wire GroupMembersVC**

Replace the stub body:

```swift
    var membersArray: [WAPProfile] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        indicator.startAnimating()
        reload()
    }

    func reload() {
        Task {
            do {
                let members = try await WAPData.shared.fetchGroupMembers(conversationId: groupID)
                await MainActor.run {
                    self.membersArray = members
                    self.tableView.reloadData()
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { membersArray.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let profile = membersArray[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GroupMembersCell", for: indexPath) as? GroupMembersCell else {
            assertionFailure("GroupMembersVC storyboard cell identifier drifted from \"GroupMembersCell\"")
            return UITableViewCell()
        }
        cell.configure(profile: profile)
        return cell
    }
```

`GroupMembersCell` doesn't exist in this codebase yet (confirmed absent from the earlier full-file listing this plan was written against) — grep `grep -rn "GroupMembersCell" "The W App"` to double check, then add a small `UITableViewCell` subclass with an avatar `UIImageView` + name `UILabel` and a `configure(profile: WAPProfile)` method, mirroring `LocationPersonCell`'s structure, and register its identifier in the storyboard before wiring `cellForRowAt` above.

- [ ] **Step 3: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
cd /Users/sr/W-legacy-repo
git add "The W App/Group Chat/GroupChatVC.swift" "The W App/Group Chat/GroupMembersVC.swift"
git commit -m "feat(phase14): wire GroupChatVC and GroupMembersVC to WAPData"
```

---

### Task 6: Wire SelectUsersVC + SendMessageVC (compose flow)

**Files:**
- Modify: `The W App/Send Message/SelectUsersVC.swift`
- Modify: `The W App/Send Message/SendMessageVC.swift`
- Modify: `The W App/Classes/WAPData.swift` (add `fetchAllProfiles`)

**Interfaces:**
- Consumes: `WAPData.shared.startConversation(recipientIds:name:isGroup:firstMessage:)` (Task 2), existing `UserClass`, existing `SelectUserCell`.
- Produces: `SendMessageVC.isGroup: Bool` (new property).

- [ ] **Step 1: Add `fetchAllProfiles` to WAPData**

Append to the `// MARK: - Messaging` section added in Task 2:

```swift
    func fetchAllProfiles() async throws -> [WAPProfile] {
        guard let uid = WAPAuth.currentUserID else { return [] }
        return try await client
            .from("profiles")
            .select()
            .neq("id", value: uid)
            .limit(200)
            .execute()
            .value
    }
```

- [ ] **Step 2: Load candidate recipients in SelectUsersVC**

Replace `viewDidLoad`:

```swift
    override func viewDidLoad() {
        super.viewDidLoad()
        allSelectedView.isHidden = true
        sendButton.isEnabled = false
        setKeyboard()
        indicator.startAnimating()
        reload()
    }

    func reload() {
        Task {
            do {
                let profiles = try await WAPData.shared.fetchAllProfiles()
                await MainActor.run {
                    self.allArray = profiles.map { profile in
                        UserClass(imageView: UIImageView(), id: profile.id, name: profile.displayName,
                                  age: "", gender: "", country: profile.nationality ?? "", city: profile.city ?? "",
                                  isSelected: false)
                    }
                    self.usersArray = self.allArray
                    self.tableView.reloadData()
                    self.indicator.stopAnimating()
                    self.allLabel.text = "Select all (\(self.usersArray.count))"
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

Before implementing, run `find "The W App" -iname "UserClass.swift"` and inspect its initializer — this plan assumes `UserClass(imageView:id:name:age:gender:country:city:isSelected:)` matching the pre-Phase-8 legacy shape already seen in the design spec's research, but confirm the live signature (parameter names/order/optionality) hasn't drifted before matching it above.

- [ ] **Step 3: Pass selection to SendMessageVC and call startConversation**

Replace `sendMessage(_:)` in `SelectUsersVC`:

```swift
    @IBAction func sendMessage(_ sender: UIButton) {
        let selected = usersArray.filter { $0.isSelected }
        guard !selected.isEmpty else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "SendMessageVC") as? SendMessageVC {
            vc.usersArray = selected
            vc.isGroup = selected.count > 1
            vc.modalPresentationStyle = .currentContext
            present(vc, animated: true)
        }
    }
```

Replace `SendMessageVC` entirely:

```swift
import UIKit

class SendMessageVC: UIViewController {

    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var sendIndicator: UIActivityIndicatorView!

    var usersArray: [UserClass] = []
    var isGroup = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func send(_ sender: UIButton) {
        view.endEditing(true)
        let text = messageTextView.getText()
        guard !text.isEmpty else {
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        sendButton.isHidden = true
        sendIndicator.startAnimating()
        Task {
            do {
                let name = isGroup ? usersArray.map { $0.name }.joined(separator: ", ") : nil
                _ = try await WAPData.shared.startConversation(
                    recipientIds: usersArray.map { $0.id },
                    name: name,
                    isGroup: isGroup,
                    firstMessage: text
                )
                await MainActor.run {
                    AlertClass().showSuccessAlert(delegate: self, message: Strings.alertMessageSent) { [weak self] in
                        self?.dismiss(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.sendButton.isHidden = false
                    self.sendIndicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }
}
```

- [ ] **Step 4: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
cd /Users/sr/W-legacy-repo
git add "The W App/Send Message/SelectUsersVC.swift" "The W App/Send Message/SendMessageVC.swift" "The W App/Classes/WAPData.swift"
git commit -m "feat(phase14): wire SelectUsersVC + SendMessageVC to WAPData.startConversation"
```

---

## Verification

1. All six tasks committed, `xcodebuild ... build` succeeds at HEAD.
2. Run migration `012_messaging.sql` in the Supabase SQL Editor (not automated — user step).
3. Manual: from `SelectUsersVC`, pick one user, send a message — recipient sees it in `MessagesVC` under "Messages" with a "Request" badge if not already friends; recipient opens `ChatVC`, sees Accept/Decline, accepts, replies — sender sees the reply on next `reload()`.
4. Manual: pick 2+ users, send a message — creates a group conversation, visible under "Groups" tab for all recipients (all `accepted` immediately, no request gate); `GroupChatVC`'s menu button opens `GroupMembersVC` listing all participants.
5. Manual: reject a 1:1 request — sender's conversation shows `myStatus == "rejected"`; confirm RLS blocks the rejected recipient from sending further messages into that conversation (should throw, caught and shown as an alert, not crash).

## Known Deferred (per spec's Non-Goals)

- No Supabase Realtime — refresh-on-appear and pull-to-refresh only.
- No read receipts, typing indicators, or unread counts beyond the pending-request badge.
- No group-invite request flow.
- No message editing/deletion, no push notifications.
- Phase 15 (audience filters + organizer broadcast) is a separate, not-yet-designed follow-up — not covered here.
