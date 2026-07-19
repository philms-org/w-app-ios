import Foundation
import Supabase

// Central Supabase data service. Replaces all .php URLSession calls.
// All methods are async throws; callers catch and show AlertClass errors.
final class WAPData {
    static let shared = WAPData()
    private init() {}

    private var client: SupabaseClient { WAPSupabase.shared.client }

    // MARK: - Profile

    func fetchProfile(id: String) async throws -> WAPProfile {
        try await client
            .from("profiles")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    func upsertProfile(_ profile: WAPProfile) async throws {
        try await client
            .from("profiles")
            .upsert(profile)
            .execute()
    }

    // MARK: - Venues

    func fetchVenues() async throws -> [WAPVenue] {
        try await client
            .from("locations")
            .select()
            .order("name")
            .execute()
            .value
    }

    func fetchVenue(id: String) async throws -> WAPVenue {
        try await client
            .from("locations")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    func fetchMyVenue() async throws -> WAPVenue? {
        guard let uid = WAPAuth.currentUserID else { return nil }
        let results: [WAPVenue] = try await client
            .from("locations")
            .select()
            .eq("owner_id", value: uid)
            .eq("is_event", value: false)
            .limit(1)
            .execute()
            .value
        return results.first
    }

    func updateVenue(_ venue: WAPVenue) async throws {
        try await client
            .from("locations")
            .update([
                "address": venue.address ?? "",
                "description": venue.description ?? "",
                "whatsapp": venue.whatsapp ?? "",
                "default_message": venue.defaultMessage ?? ""
            ])
            .eq("id", value: venue.id)
            .execute()
    }

    func createEvent(name: String, description: String, startDate: String, endDate: String) async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        try await client
            .from("locations")
            .insert([
                "name": name,
                "description": description,
                "event_date": startDate,
                "event_end_date": endDate,
                "is_event": "true",
                "owner_id": uid,
                "lat": "0",
                "lng": "0"
            ])
            .execute()
    }

    func fetchEvents() async throws -> [WAPVenue] {
        guard let uid = WAPAuth.currentUserID else { return [] }
        return try await client
            .from("locations")
            .select()
            .eq("is_event", value: true)
            .eq("owner_id", value: uid)
            .order("event_date", ascending: false)
            .execute()
            .value
    }

    func updateEvent(_ venue: WAPVenue) async throws {
        try await client
            .from("locations")
            .update([
                "name": venue.name,
                "description": venue.description ?? "",
                "event_date": venue.eventDate ?? "",
                "event_end_date": venue.eventEndDate ?? "",
                "event_status": venue.eventStatus ?? "Active"
            ])
            .eq("id", value: venue.id)
            .execute()
    }

    // MARK: - Feed

    func fetchFeed(locationId: String) async throws -> [WAPFeedItem] {
        try await client
            .from("feed_posts")
            .select("*, profiles(*)")
            .eq("location_id", value: locationId)
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value
    }

    func postToFeed(locationId: String, text: String) async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        struct Post: Encodable {
            let location_id: String
            let user_id: String
            let content: String
        }
        try await client
            .from("feed_posts")
            .insert(Post(location_id: locationId, user_id: uid, content: text))
            .execute()
    }

    // MARK: - Presence (who's here)

    func fetchPresence(locationId: String) async throws -> [WAPPresence] {
        try await client
            .from("location_checkins")
            .select("*, profiles(*)")
            .eq("location_id", value: locationId)
            .is("checked_out_at", value: nil)
            .execute()
            .value
    }

    func checkIn(locationId: String) async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        struct CheckIn: Encodable {
            let user_id: String
            let location_id: String
            let mode: String
        }
        try await client
            .from("location_checkins")
            .insert(CheckIn(user_id: uid, location_id: locationId, mode: "live"))
            .execute()
    }

    func checkOut(locationId: String) async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        struct CheckOut: Encodable { let checked_out_at: String }
        let now = ISO8601DateFormatter().string(from: Date())
        try await client
            .from("location_checkins")
            .update(CheckOut(checked_out_at: now))
            .eq("user_id", value: uid)
            .eq("location_id", value: locationId)
            .is("checked_out_at", value: nil)
            .execute()
    }

    // MARK: - Contact Methods

    func fetchContactMethods(userId: String) async throws -> [WAPContactMethod] {
        try await client
            .from("contact_methods")
            .select()
            .eq("user_id", value: userId)
            .order("slot_order")
            .execute()
            .value
    }

    func upsertContactMethod(_ method: WAPContactMethod) async throws {
        try await client
            .from("contact_methods")
            .upsert(method)
            .execute()
    }

    // MARK: - Rewards

    func fetchRewards(locationId: String) async throws -> [WAPReward] {
        try await client
            .from("rewards")
            .select()
            .eq("location_id", value: locationId)
            .eq("is_active", value: true)
            .order("display_order")
            .execute()
            .value
    }

    func hasFeatureAccess(featureName: String) async throws -> Bool {
        guard let uid = WAPAuth.currentUserID else { return false }
        struct AccessRow: Decodable { let user_id: String }
        let rows: [AccessRow] = try await client
            .from("user_feature_access")
            .select("user_id")
            .eq("user_id", value: uid)
            .eq("feature_name", value: featureName)
            .execute()
            .value
        return !rows.isEmpty
    }

    // MARK: - Attendee History

    func resolveFeatureFlag(featureName: String, userId: String, location: WAPVenue) async throws -> Bool {
        let overrides: [WAPFeatureFlagOverride] = try await client
            .from("feature_flag_overrides")
            .select()
            .eq("feature_name", value: featureName)
            .execute()
            .value
        let defaults: [WAPFeatureFlagDefault] = try await client
            .from("feature_flags")
            .select()
            .eq("feature_name", value: featureName)
            .execute()
            .value
        return WAPFeatureFlagResolver.resolve(
            overrides: overrides,
            defaultEnabled: defaults.first?.defaultEnabled ?? false,
            locationId: location.id,
            userId: userId,
            city: location.city
        )
    }

    func fetchAttendeeHistory(locationId: String) async throws -> [WAPProfile] {
        struct CheckinRow: Decodable { let profiles: WAPProfile }
        let rows: [CheckinRow] = try await client
            .from("location_checkins")
            .select("profiles(*)")
            .eq("location_id", value: locationId)
            .eq("mode", value: "live")
            .execute()
            .value
        struct OptOutRow: Decodable { let user_id: String }
        let optOuts: [OptOutRow] = try await client
            .from("attendee_history_opt_outs")
            .select("user_id")
            .eq("location_id", value: locationId)
            .execute()
            .value
        let optedOutIds = Set(optOuts.map(\.user_id))
        var seen = Set<String>()
        var result: [WAPProfile] = []
        for row in rows {
            let profile = row.profiles
            guard !optedOutIds.contains(profile.id), !seen.contains(profile.id) else { continue }
            seen.insert(profile.id)
            result.append(profile)
        }
        return result
    }

    func isOptedOutOfAttendeeHistory(locationId: String) async throws -> Bool {
        guard let uid = WAPAuth.currentUserID else { return false }
        struct OptOutCheck: Decodable { let user_id: String }
        let rows: [OptOutCheck] = try await client
            .from("attendee_history_opt_outs")
            .select("user_id")
            .eq("location_id", value: locationId)
            .eq("user_id", value: uid)
            .execute()
            .value
        return !rows.isEmpty
    }

    func setAttendeeHistoryOptOut(locationId: String, hidden: Bool) async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        if hidden {
            struct OptOut: Encodable { let user_id: String; let location_id: String }
            try await client
                .from("attendee_history_opt_outs")
                .upsert(OptOut(user_id: uid, location_id: locationId))
                .execute()
        } else {
            try await client
                .from("attendee_history_opt_outs")
                .delete()
                .eq("user_id", value: uid)
                .eq("location_id", value: locationId)
                .execute()
        }
    }

    // MARK: - Avatar Storage

    func uploadAvatar(imageData: Data, userId: String) async throws -> String {
        let path = "\(userId)/avatar.jpg"
        try await client.storage
            .from("avatars")
            .upload(path: path, file: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))
        let url = try client.storage.from("avatars").getPublicURL(path: path)
        return url.absoluteString
    }

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

    func fetchConversationStatus(conversationId: String) async throws -> String {
        guard let uid = WAPAuth.currentUserID else { return "accepted" }
        struct StatusRow: Codable {
            let status: String
        }
        let row: StatusRow = try await client
            .from("conversation_participants")
            .select("status")
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: uid)
            .single()
            .execute()
            .value
        return row.status
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
}
