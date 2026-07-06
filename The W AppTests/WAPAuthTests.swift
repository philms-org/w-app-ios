import XCTest
@testable import TheWApp

final class WAPAuthTests: XCTestCase {
    func testCurrentUserIDNilWhenNoToken() {
        KeychainHelper.delete(key: KeychainHelper.Keys.authToken)
        XCTAssertNil(WAPAuth.currentUserID)
    }

    func testCurrentUserIDReturnsSavedToken() {
        KeychainHelper.save(key: KeychainHelper.Keys.authToken, value: "uid-abc-123")
        XCTAssertEqual(WAPAuth.currentUserID, "uid-abc-123")
        KeychainHelper.delete(key: KeychainHelper.Keys.authToken)
    }
}
