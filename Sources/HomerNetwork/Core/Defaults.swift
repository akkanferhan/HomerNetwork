import Foundation

/// Library-wide default values that apply to every request unless overridden
/// at the configuration or endpoint level.
public enum HomerNetworkDefaults {
    /// The fallback request timeout, in seconds, applied when neither
    /// ``API/timeout`` nor ``NetworkClientConfiguration/defaultTimeout`` is
    /// explicitly set.
    public static let timeoutInterval: TimeInterval = 30
}
