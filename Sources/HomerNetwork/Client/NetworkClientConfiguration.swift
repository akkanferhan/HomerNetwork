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

    public init(
        session: any URLSessionProtocol = URLSession.shared,
        defaultHeaders: HTTPHeaders = [:],
        defaultTimeout: TimeInterval = 30,
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
