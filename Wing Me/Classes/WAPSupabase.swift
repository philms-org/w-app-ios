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
