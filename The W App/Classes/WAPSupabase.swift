import Foundation
import Supabase

final class WAPSupabase {
    static let shared = WAPSupabase()

    let client: SupabaseClient

    private init() {
        let url = URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "")!
        let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
}
