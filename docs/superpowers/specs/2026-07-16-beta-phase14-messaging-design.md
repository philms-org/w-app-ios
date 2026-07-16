# Beta Phase 14 — Messaging (1:1 + Group)

## Context

Phase 8 stripped all CoreData/PHP messaging code down to empty-state stubs (`MessagesVC`, `ChatVC`, `GroupChatVC`, `GroupMembersVC`, `SendMessageVC`, `SelectUsersVC`), preserving every `@IBOutlet`/`@IBAction` the storyboard wires to. No `messages`/`conversations` tables exist in the schema — this is genuinely new backend surface, not a reconciliation pass like prior phases. This spec wires those six screens to a new Supabase-backed messaging system, matching the async/await `WAPData` fetch/upsert style used everywhere else (no Realtime — refresh-on-appear + pull-to-refresh, consistent with the rest of the app).

`ReplyVC` (feed-post comment replies) is a different, already-partially-wired subsystem and is explicitly out of scope here.

## Schema (migration `012_messaging.sql`)

```sql
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
```

RLS: a user may `select` a `conversations`/`messages` row only if a matching `conversation_participants` row exists for `auth.uid()` (any status — pending requests must stay visible to both sender and recipient so the request shows up in the recipient's inbox). `insert` on `messages` requires the sender's participant row to have `status = 'accepted'` (blocks sending into a conversation you haven't accepted). `update` on `conversation_participants.status` is restricted to the row's own `user_id` (only the recipient accepts/rejects their own pending row).

**1:1 request semantics:** when `startConversation` creates a 1:1 (non-group) conversation, the initiator's participant row is `accepted`; the recipient's row is `accepted` if a `friendships` row already exists between the two users (existing table, Phase 0 schema), else `pending`. Group conversations: all participants the creator adds start `accepted` (no request flow for group invites in this phase — see `Non-Goals`).

## Data Layer (`WAPData.swift`)

| Function | Signature | Notes |
|---|---|---|
| `fetchConversations` | `() async throws -> [WAPConversation]` | All conversations where the current user has any participant row; each result includes last-message preview + the other participant's profile (1:1) or group name (group). Split into "Messages" vs "Groups" tabs client-side on `isGroup`. |
| `fetchMessages` | `(conversationId: String) async throws -> [WAPMessage]` | Ordered by `created_at` ascending, joined `profiles` for sender display. |
| `sendMessage` | `(conversationId: String, content: String) async throws` | Inserts into `messages`; RLS blocks this unless the sender's participant status is `accepted`. |
| `startConversation` | `(recipientIds: [String], name: String?, isGroup: Bool, firstMessage: String) async throws -> WAPConversation` | Creates the `conversations` row, one `conversation_participants` row per recipient (status per the rule above) plus the creator (`accepted`), then inserts `firstMessage` via `sendMessage`. |
| `respondToConversationRequest` | `(conversationId: String, accept: Bool) async throws` | Updates the current user's own participant row to `accepted`/`rejected`. |
| `fetchGroupMembers` | `(conversationId: String) async throws -> [WAPProfile]` | Participant profiles for a group conversation, for `GroupMembersVC`. |

## Models (`WAPModels.swift`)

```swift
struct WAPConversation: Codable, Identifiable {
    let id: String
    var isGroup: Bool
    var name: String?
    var lastMessage: String?
    var lastMessageAt: String?
    var myStatus: String       // "pending" | "accepted" | "rejected", for the current user's own row
    var otherProfile: WAPProfile?   // populated for 1:1 only
}

struct WAPMessage: Codable, Identifiable {
    let id: String
    let conversationId: String
    let senderId: String
    var content: String
    var createdAt: String
    var profile: WAPProfile?
}
```

`CodingKeys` follow the existing snake_case convention (`is_group`, `created_by`, `conversation_id`, `sender_id`, `created_at`, etc.), matching every other model in the file.

## UI Wiring

Every screen preserves its existing `@IBOutlet`/`@IBAction` set exactly (storyboard-wired, KVC crash on load if any go missing — established pattern from Phases 2 and 6). No force-unwraps; `[weak self]` in every closure/`Task`; loading states via each screen's existing `indicator`.

- **`MessagesVC`** — `viewWillAppear` calls `fetchConversations()`, splits into `messagesTableView` (1:1) / `groupsTableView` (group) per the existing `selectTab` tab switcher; `noMessagesView` shown when the active tab's array is empty. Pending 1:1 requests show a "Request" badge in the row (no new outlet needed — reuse the existing cell's secondary label).
- **`ChatVC`** — loads `fetchMessages()` for the conversation; `acceptView`/`acceptButton`/`rejectButton` shown only when the current user is the pending recipient (`myStatus == "pending"`), wired to `respondToConversationRequest`; hides `genderView` and `checkmarkImageView` (dating-era leftovers, same treatment as `UserProfileVC` in Phase 6); `sendButton` calls `sendMessage`.
- **`GroupChatVC`** — same message-loading/send pattern as `ChatVC`, no accept/reject (groups have no request flow); `menuButton` pushes `GroupMembersVC`.
- **`GroupMembersVC`** — `fetchGroupMembers()` populates `tableView`.
- **`SelectUsersVC`** — `searchTextField`/`editingChanged` filters a fetched profile list (reuse an existing profile-search query if one exists in `WAPData`, otherwise a simple `ilike` on `profiles.display_name`); `selectAllUsers` toggles multi-select for group composition; `sendMessage` action passes selected user IDs + composed text to `SendMessageVC` (or directly calls `startConversation` if `SendMessageVC` turns out to be redundant with this screen — implementer to confirm the existing navigation flow between the two before deciding).
- **`SendMessageVC`** — `send` action calls `startConversation(recipientIds:name:isGroup:firstMessage:)`, dismisses on success.

## Testing

No functional XCTest target exists in this project (confirmed in the Attendee History plan). Verification is build-success + code review, same as every prior phase; test files may be written for documentation but `xcodebuild test` is not run.

## Non-Goals

- No Supabase Realtime / live-updating threads — refresh-on-appear and pull-to-refresh only.
- No read receipts, typing indicators, or unread-count badges beyond the pending-request marker.
- No group-invite request flow — group participants are added directly as `accepted` (only 1:1 has the pending/accept gate).
- No message editing or deletion.
- No changes to `ReplyVC` or feed-comment replies — separate subsystem.
- No push notifications for new messages.
