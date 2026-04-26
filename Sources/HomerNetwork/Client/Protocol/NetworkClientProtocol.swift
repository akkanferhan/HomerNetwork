import Foundation

/// The library's primary entry point: an `actor`-isolated client that
/// turns an ``Endpoint`` into a typed ``NetworkResponse`` over async/await.
///
/// `NetworkClient` is a protocol so consumers can substitute a stub during
/// tests; the production implementation is ``DefaultNetworkClient``.
public protocol NetworkClientProtocol: Sendable {
    /// Sends `endpoint` and returns the decoded ``NetworkResponse``.
    /// Throws ``NetworkError`` on transport, encoding, decoding, or
    /// reachability failures.
    func send<E: Endpoint>(_ endpoint: E) async throws -> NetworkResponse<E.Response>
}
