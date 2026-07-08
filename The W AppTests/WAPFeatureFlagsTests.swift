import XCTest
@testable import The_W_App

final class WAPFeatureFlagsTests: XCTestCase {
    func testLocationOverrideWinsOverEverything() {
        let overrides = [
            WAPFeatureFlagOverride(featureName: "attendee_history_view", scopeType: "location", scopeValue: "loc-1", enabled: false),
            WAPFeatureFlagOverride(featureName: "attendee_history_view", scopeType: "user", scopeValue: "user-1", enabled: true),
            WAPFeatureFlagOverride(featureName: "attendee_history_view", scopeType: "city", scopeValue: "Austin", enabled: true),
        ]
        let result = WAPFeatureFlagResolver.resolve(
            overrides: overrides, defaultEnabled: true,
            locationId: "loc-1", userId: "user-1", city: "Austin"
        )
        XCTAssertFalse(result, "location override (false) must win over user/city overrides (true)")
    }

    func testUserOverrideWinsOverCityAndGlobal() {
        let overrides = [
            WAPFeatureFlagOverride(featureName: "attendee_history_view", scopeType: "user", scopeValue: "user-1", enabled: true),
            WAPFeatureFlagOverride(featureName: "attendee_history_view", scopeType: "city", scopeValue: "Austin", enabled: false),
        ]
        let result = WAPFeatureFlagResolver.resolve(
            overrides: overrides, defaultEnabled: false,
            locationId: "loc-1", userId: "user-1", city: "Austin"
        )
        XCTAssertTrue(result, "user override (true) must win over city override (false) and global default (false)")
    }

    func testCityOverrideWinsOverGlobal() {
        let overrides = [
            WAPFeatureFlagOverride(featureName: "attendee_history_view", scopeType: "city", scopeValue: "Austin", enabled: true),
        ]
        let result = WAPFeatureFlagResolver.resolve(
            overrides: overrides, defaultEnabled: false,
            locationId: "loc-1", userId: "user-1", city: "Austin"
        )
        XCTAssertTrue(result)
    }

    func testFallsBackToGlobalDefaultWhenNoOverridesMatch() {
        let result = WAPFeatureFlagResolver.resolve(
            overrides: [], defaultEnabled: true,
            locationId: "loc-1", userId: "user-1", city: nil
        )
        XCTAssertTrue(result)
    }
}
