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
}
