import Foundation

/// The library's primary entry point: an `actor`-isolated client that
/// turns an ``Endpoint`` into a typed ``NetworkResponse`` over
/// async / await.
///
/// `NetworkClientProtocol` is a protocol so consumers can substitute a
/// stub during tests; the production implementation is ``NetworkManager``.
public protocol NetworkClientProtocol: Sendable {
    /// Sends `endpoint` and returns the decoded ``NetworkResponse``.
    ///
    /// - Throws: ``NetworkError`` cases — ``NetworkError/offline`` if the
    ///   pre-flight ``ConnectivityProbing`` reports unreachable;
    ///   ``NetworkError/encoding(_:)`` / ``NetworkError/invalidRequest``
    ///   on request build failure; ``NetworkError/transport(_:)``,
    ///   ``NetworkError/cancelled``, or ``NetworkError/invalidResponse``
    ///   on transport failure; ``NetworkError/http(status:data:)`` on
    ///   non-2xx with `validateHTTPStatus = true`;
    ///   ``NetworkError/decoding(_:data:)`` on response decode failure.
    func send<E: Endpoint>(_ endpoint: E) async throws -> NetworkResponse<E.Response>
}
