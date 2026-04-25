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
    public init(
        session: any URLSessionProtocol = URLSession(configuration: .ephemeral),
        defaultHeaders: HTTPHeaders = [:],
        defaultTimeout: TimeInterval = HomerNetworkDefaults.timeoutInterval,
        logger: any NetworkLogger = NoopNetworkLogger(),
        validateHTTPStatus: Bool = true
    ) {
        self.session = session
        self.defaultHeaders = defaultHeaders
        self.defaultTimeout = defaultTimeout
        self.logger = logger
        self.validateHTTPStatus = validateHTTPStatus
    }
}
