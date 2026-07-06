import Foundation
import Supabase

enum WAPAuth {
    static var currentUserID: String? {
        KeychainHelper.load(key: KeychainHelper.Keys.authToken)
    }

    static func signInWithPhone(phone: String) async throws {
        try await WAPSupabase.shared.client.auth.signInWithOTP(phone: phone)
    }

    static func verifyOTP(phone: String, token: String) async throws {
        let session = try await WAPSupabase.shared.client.auth.verifyOTP(
            phone: phone, token: token, type: .sms
        )
        KeychainHelper.save(
            key: KeychainHelper.Keys.authToken,
            value: session.user.id.uuidString
        )
    }

    static func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await WAPSupabase.shared.client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        KeychainHelper.save(
            key: KeychainHelper.Keys.authToken,
            value: session.user.id.uuidString
        )
    }

    static func signInWithFacebook(accessToken: String) async throws {
        let session = try await WAPSupabase.shared.client.auth.signInWithIdToken(
            credentials: .init(provider: .facebook, idToken: accessToken)
        )
        KeychainHelper.save(
            key: KeychainHelper.Keys.authToken,
            value: session.user.id.uuidString
        )
    }

    static func signOut() async {
        try? await WAPSupabase.shared.client.auth.signOut()
        KeychainHelper.delete(key: KeychainHelper.Keys.authToken)
    }
}
