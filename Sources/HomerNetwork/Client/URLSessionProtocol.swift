import Foundation

/// The slice of `URLSession`'s API that ``DefaultNetworkClient`` consumes.
///
/// Conforming a mock type to this protocol is the supported way to swap
/// the transport in tests; `URLSession` itself conforms in an extension.
public protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}
