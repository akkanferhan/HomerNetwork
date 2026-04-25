import Foundation

/// A pluggable observer for outgoing requests and incoming responses.
///
/// Conformers see every request/response pair processed by ``NetworkClient``;
/// implementations should be inexpensive and side-effect free (typically
/// writing to `os.Logger` or a file). Default implementations exist for
/// no-op (``NoopNetworkLogger``) and `os.Logger` (``OSLogNetworkLogger``).
public protocol NetworkLogger: Sendable {
    func log(request: URLRequest)
    func log(response: HTTPURLResponse, data: Data)
    func log(error: any Error)
}

public extension NetworkLogger {
    func log(response: HTTPURLResponse, data: Data) {}
    func log(error: any Error) {}
}
