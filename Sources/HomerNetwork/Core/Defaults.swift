import Foundation

/// Library-wide default values that apply to every request unless
/// overridden at the configuration or endpoint level.
///
/// Re-promoted to `public` in `0.6.0` so the same constant can serve as
/// the default argument for both
/// ``NetworkClientConfiguration/init(session:defaultHeaders:defaultTimeout:logger:validateHTTPStatus:reachability:retryPolicy:)``
/// and ``Endpoint/timeout``, eliminating the duplicated literal `30`
/// that had drifted between the two call sites in `0.4.x` / `0.5.x`.
public enum HomerNetworkDefaults {
    /// The fallback request timeout, in seconds, applied when neither
    /// ``Endpoint/timeout`` nor
    /// ``NetworkClientConfiguration/defaultTimeout`` is explicitly set.
    public static let timeoutInterval: TimeInterval = 30
}
