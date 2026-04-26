import Foundation

/// A ``NetworkLogger`` that discards every event. The default for
/// ``NetworkClientConfiguration`` when no logger is supplied.
public struct NoopNetworkLogger: NetworkLogger {
    /// Creates a no-op logger.
    public init() {}
    /// Discards the request event.
    public func log(request: URLRequest) {}
    /// Discards the response event.
    public func log(response: HTTPURLResponse, data: Data) {}
    /// Discards the error event.
    public func log(error: any Error) {}
}
