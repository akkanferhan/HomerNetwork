import Foundation

/// The injectable configuration for ``DefaultNetworkClient``.
///
/// Construct one and pass it to ``DefaultNetworkClient/init(configuration:)``.
/// Callers wishing to override the transport (for tests, replay, …) supply
/// their own ``URLSessionProtocol``.
public struct NetworkClientConfiguration: Sendable {
    public var session: any URLSessionProtocol
    public var defaultHeaders: HTTPHeaders
    public var defaultTimeout: TimeInterval
    public var logger: any NetworkLogger
    public var validateHTTPStatus: Bool
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
