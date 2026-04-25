import Foundation

/// A ``NetworkLogger`` that discards every event. The default for
/// ``NetworkClientConfiguration`` when no logger is supplied.
public struct NoopNetworkLogger: NetworkLogger {
    public init() {}
    public func log(request: URLRequest) {}
}
