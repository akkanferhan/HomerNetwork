import Foundation

/// The injectable configuration for ``DefaultNetworkClient``.
///
/// Construct one and pass it to ``DefaultNetworkClient/init(configuration:)``.
/// Callers wishing to override the transport (for tests, replay, …) supply
/// their own ``URLSessionProtocol``.
public struct NetworkClientConfiguration: Sendable {
    /// Transport used to send requests; conforms to ``URLSessionProtocol`` so
    /// tests can swap it for a stub.
    public var session: any URLSessionProtocol
    /// Headers merged into every request before ``Endpoint``-level overrides.
    public var defaultHeaders: HTTPHeaders
    /// Fallback request timeout, in seconds, applied when the endpoint
    /// reports a non-positive value.
    public var defaultTimeout: TimeInterval
    /// Sink consulted on every request, response, and error.
    public var logger: any NetworkLogger
    /// When `true`, non-2xx responses throw ``NetworkError/http(status:data:)``
    /// instead of being decoded.
    public var validateHTTPStatus: Bool
    /// Pre-flight connectivity gate consulted before every request.
    public var reachability: any ReachabilityProviding

    /// - Parameters:
    ///   - session: Transport used to send requests. Defaults to a fresh
    ///     ephemeral `URLSession` so cookies and disk cache are isolated
    ///     per ``DefaultNetworkClient``; pass `URLSession.shared` only if
    ///     you explicitly want app-wide cookie sharing.
    ///   - defaultHeaders: Headers merged into every request before
    ///     ``Endpoint``-specific overrides.
    ///   - defaultTimeout: Fallback timeout when the endpoint reports
    ///     `0`. Defaults to ``HomerNetworkDefaults/timeoutInterval``.
    ///   - logger: Network logger sink.
    ///   - validateHTTPStatus: When `true` (default), non-2xx responses
    ///     throw ``NetworkError/http(status:data:)`` instead of being
    ///     decoded.
    ///   - reachability: Pre-flight connectivity gate consulted before
    ///     every request. Defaults to ``DefaultReachabilityChecker``,
    ///     which performs a one-shot `NWPathMonitor` probe per call.
    ///     Inject a long-lived ``HomerFoundation/Reachability`` for
    ///     better throughput, or a stub returning `true` to disable the
    ///     gate entirely (e.g. in unit tests or replay sessions).
    public init(
        session: any URLSessionProtocol = URLSession(configuration: .ephemeral),
        defaultHeaders: HTTPHeaders = [:],
        defaultTimeout: TimeInterval = HomerNetworkDefaults.timeoutInterval,
        logger: any NetworkLogger = NoopNetworkLogger(),
        validateHTTPStatus: Bool = true,
        reachability: any ReachabilityProviding = DefaultReachabilityChecker()
    ) {
        self.session = session
        self.defaultHeaders = defaultHeaders
        self.defaultTimeout = defaultTimeout
        self.logger = logger
        self.validateHTTPStatus = validateHTTPStatus
        self.reachability = reachability
    }
}
