import XCTest
@testable import TheWApp

final class KeychainHelperTests: XCTestCase {
    override func tearDown() {
        KeychainHelper.delete(key: "test_key")
        super.tearDown()
    }

    func testSaveAndLoad() {
        KeychainHelper.save(key: "test_key", value: "test_value")
        XCTAssertEqual(KeychainHelper.load(key: "test_key"), "test_value")
    }

    func testOverwrite() {
        KeychainHelper.save(key: "test_key", value: "first")
        KeychainHelper.save(key: "test_key", value: "second")
        XCTAssertEqual(KeychainHelper.load(key: "test_key"), "second")
    }

    func testDelete() {
        KeychainHelper.save(key: "test_key", value: "value")
        KeychainHelper.delete(key: "test_key")
        XCTAssertNil(KeychainHelper.load(key: "test_key"))
    }

    func testMissingKeyReturnsNil() {
        XCTAssertNil(KeychainHelper.load(key: "nonexistent_xyz"))
    }
}
