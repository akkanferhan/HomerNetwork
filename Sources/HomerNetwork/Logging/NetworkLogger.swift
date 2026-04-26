import Foundation

/// A pluggable observer for outgoing requests and incoming responses.
///
/// Conformers see every request/response pair processed by ``NetworkClient``;
/// implementations should be inexpensive and side-effect free (typically
/// writing to `os.Logger` or a file). All three methods are required so
/// silent overrides are explicit — use ``NoopNetworkLogger`` when no
/// logging is desired.
public protocol NetworkLogger: Sendable {
    /// Called immediately before the transport sends `request`.
    func log(request: URLRequest)
    /// Called when a response (any status) and its body bytes have been received.
    func log(response: HTTPURLResponse, data: Data)
    /// Called for any error produced by the encoding, transport, or decoding stage.
    func log(error: any Error)
}
