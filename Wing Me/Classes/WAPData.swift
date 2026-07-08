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

    // MARK: - Feed

    func fetchFeed(venueId: String) async throws -> [WAPFeedItem] {
        try await client
            .from("feed_posts")
            .select("*, profiles(*)")
            .eq("venue_id", value: venueId)
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value
    }

    func postToFeed(venueId: String, text: String) async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        struct Post: Encodable {
            let venue_id: String
            let user_id: String
            let text: String
        }
        try await client
            .from("feed_posts")
            .insert(Post(venue_id: venueId, user_id: uid, text: text))
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

    // MARK: - Social Links

    func fetchLinks(userId: String) async throws -> [WAPSocialLink] {
        try await client
            .from("social_links")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
    }

    func upsertLink(_ link: WAPSocialLink) async throws {
        try await client
            .from("social_links")
            .upsert(link)
            .execute()
    }

    // MARK: - Rewards

    func fetchRewards(venueId: String, tier: String) async throws -> [WAPReward] {
        try await client
            .from("rewards")
            .select()
            .eq("venue_id", value: venueId)
            .eq("tier", value: tier)
            .execute()
            .value
    }
}
