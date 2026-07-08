import Foundation
import Supabase

final class WAPSupabase {
    static let shared = WAPSupabase()

    let client: SupabaseClient

    // Requires SUPABASE_URL and SUPABASE_ANON_KEY in Xcode Edit Scheme → Environment Variables
    private init() {
        guard let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"],
              let url = URL(string: urlString) else {
            fatalError("SUPABASE_URL environment variable not set or invalid")
        }
        guard let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !key.isEmpty else {
            fatalError("SUPABASE_ANON_KEY environment variable not set")
        }
        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
}

// Registration-time profile upsert (id/display_name/phone/gender/date_of_birth/avatar_url).
// Lives on WAPSupabase (a plain, non-actor-isolated class) rather than inline in the
// registration view controllers so the .execute() call doesn't cross a @MainActor
// isolation boundary with a non-Sendable PostgrestResponse<Void>.
struct WAPRegistrationProfile: Encodable {
    let id: String
    let display_name: String
    let phone: String?
    let gender: String
    let date_of_birth: String
    let avatar_url: String?
}

extension WAPSupabase {
    func upsertRegistrationProfile(_ profile: WAPRegistrationProfile) async throws {
        try await client
            .from("profiles")
            .upsert(profile)
            .execute()
    }
}
