import Foundation
import Supabase

final class WAPSupabase {
    static let shared = WAPSupabase()

    let client: SupabaseClient

    private init() {
        guard let url = URL(string: WAPSecrets.supabaseURL) else {
            fatalError("Invalid Supabase URL in WAPSecrets")
        }
        client = SupabaseClient(supabaseURL: url, supabaseKey: WAPSecrets.supabaseAnonKey)
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
    let gender: String?
    let date_of_birth: String?
    let avatar_url: String?
    let affiliation: [String]?
    let industry: [String]?
    let role: [String]?
}

extension WAPSupabase {
    func upsertRegistrationProfile(_ profile: WAPRegistrationProfile) async throws {
        try await client
            .from("profiles")
            .upsert(profile)
            .execute()
    }
}
