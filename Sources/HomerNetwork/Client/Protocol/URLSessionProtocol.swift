import Foundation

/// The slice of `URLSession`'s API that ``NetworkManager`` consumes.
///
/// Conforming a mock type to this protocol is the supported way to swap
/// the transport in tests; `URLSession` itself conforms in an extension
/// below so production callers can pass `URLSession.shared` (or a
/// custom-configured session) without ceremony.
public protocol URLSessionProtocol: Sendable {
    /// Performs `request` and returns the response body alongside its
    /// `URLResponse`. Mirrors `URLSession.data(for:)`.
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}
