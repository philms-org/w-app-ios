import Foundation

struct WAPFeatureFlagOverride: Codable {
    let featureName: String
    let scopeType: String
    let scopeValue: String
    let enabled: Bool

    enum CodingKeys: String, CodingKey {
        case featureName = "feature_name"
        case scopeType   = "scope_type"
        case scopeValue  = "scope_value"
        case enabled
    }
}

struct WAPFeatureFlagDefault: Codable {
    let featureName: String
    let defaultEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case featureName    = "feature_name"
        case defaultEnabled = "default_enabled"
    }
}

enum WAPFeatureFlagResolver {
    // Resolution order: location override > user override > city override > global default.
    static func resolve(
        overrides: [WAPFeatureFlagOverride],
        defaultEnabled: Bool,
        locationId: String,
        userId: String,
        city: String?
    ) -> Bool {
        if let locationOverride = overrides.first(where: { $0.scopeType == "location" && $0.scopeValue == locationId }) {
            return locationOverride.enabled
        }
        if let userOverride = overrides.first(where: { $0.scopeType == "user" && $0.scopeValue == userId }) {
            return userOverride.enabled
        }
        if let city, let cityOverride = overrides.first(where: { $0.scopeType == "city" && $0.scopeValue == city }) {
            return cityOverride.enabled
        }
        return defaultEnabled
    }
}
