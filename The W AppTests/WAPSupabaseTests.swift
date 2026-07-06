import XCTest
@testable import The_W_App

final class WAPSupabaseTests: XCTestCase {
    func testSharedClientExists() {
        XCTAssertNotNil(WAPSupabase.shared.client)
    }
}
