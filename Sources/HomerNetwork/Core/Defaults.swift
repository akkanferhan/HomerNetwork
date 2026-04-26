import Foundation

/// Library-wide default values that apply to every request unless overridden
/// at the configuration or endpoint level.
enum HomerNetworkDefaults {
    /// The fallback request timeout, in seconds, applied when neither
    /// ``Endpoint/timeout`` nor ``NetworkClientConfiguration/defaultTimeout`` is
    /// explicitly set.
    static let timeoutInterval: TimeInterval = 30
}
