import Foundation

/// The injectable configuration for ``DefaultNetworkClient``.
///
/// Construct one and pass it to ``DefaultNetworkClient/init(configuration:)``.
/// Callers wishing to override the transport (for tests, replay, …) supply
/// their own ``URLSessionProtocol``.
public struct NetworkClientConfiguration: Sendable {
    /// Transport used to send requests; conforms to ``URLSessionProtocol`` so
    /// tests can swap it for a stub.
    public let session: any URLSessionProtocol
    /// Headers merged into every request before ``Endpoint``-level overrides.
    public let defaultHeaders: HTTPHeaders
    /// Fallback request timeout, in seconds, applied when the endpoint
    /// reports a non-positive value.
    public let defaultTimeout: TimeInterval
    /// Sink consulted on every request, response, and error.
    public let logger: any NetworkLogger
    /// When `true`, non-2xx responses throw ``NetworkError/http(status:data:)``
    /// instead of being decoded.
    public let validateHTTPStatus: Bool
    /// Pre-flight connectivity gate consulted before every request.
    public let reachability: any ReachabilityProviding

    /// - Parameters:
    ///   - session: Transport used to send requests. Defaults to a fresh
    ///     ephemeral `URLSession` so cookies and disk cache are isolated
    ///     per ``DefaultNetworkClient``; pass `URLSession.shared` only if
    ///     you explicitly want app-wide cookie sharing.
    ///   - defaultHeaders: Headers merged into every request before
    ///     ``Endpoint``-specific overrides.
    ///   - defaultTimeout: Fallback timeout, in seconds, when the endpoint
    ///     reports `0`. Defaults to `30` seconds.
    ///   - logger: Network logger sink.
    ///   - validateHTTPStatus: When `true` (default), non-2xx responses
    ///     throw ``NetworkError/http(status:data:)`` instead of being
    ///     decoded.
    ///   - reachability: Pre-flight connectivity gate consulted before
    ///     every request. When `nil` (the default), an internal one-shot
    ///     `NWPathMonitor`-backed provider is used. Inject a long-lived
    ///     ``HomerFoundation/Reachability`` for better throughput, or a
    ///     stub returning `true` to disable the gate entirely (e.g. in
    ///     unit tests or replay sessions).
    public init(
        session: any URLSessionProtocol = URLSession(configuration: .ephemeral),
        defaultHeaders: HTTPHeaders = [:],
        defaultTimeout: TimeInterval = 30,
        logger: any NetworkLogger = NoopNetworkLogger(),
        validateHTTPStatus: Bool = true,
        reachability: (any ReachabilityProviding)? = nil
    ) {
        self.session = session
        self.defaultHeaders = defaultHeaders
        self.defaultTimeout = defaultTimeout
        self.logger = logger
        self.validateHTTPStatus = validateHTTPStatus
        self.reachability = reachability ?? DefaultReachabilityChecker()
    }
}
