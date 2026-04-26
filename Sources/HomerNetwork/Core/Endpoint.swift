import Foundation

/// A typed HTTP endpoint.
///
/// Conform an enum or struct to `Endpoint` to describe a single request:
/// its path, method, body, and the type its JSON response decodes into.
///
/// ```swift
/// enum UserAPI: Endpoint {
///     case me
///
///     typealias Response = User
///     var baseURL: URL { URL(string: "https://api.example.com")! }
///     var path: String { "/v1/me" }
///     var httpMethod: HTTPMethod { .get }
///     var task: HTTPTask { .plain }
/// }
/// ```
public protocol Endpoint: API {
    /// The decoded type returned by ``NetworkClient/send(_:)``.
    associatedtype Response: Decodable & Sendable

    /// The path appended to ``API/baseURL``. Leading `/` recommended.
    var path: String { get }

    /// The HTTP verb.
    var httpMethod: HTTPMethod { get }

    /// The body / parameter / multipart shape of the request.
    var task: HTTPTask { get }

    /// Headers specific to this endpoint, merged on top of ``API/baseHeaders``.
    var headers: HTTPHeaders { get }

    /// The decoder used to parse the response body.
    var decoder: JSONDecoder { get }
}

public extension Endpoint {
    var headers: HTTPHeaders { [:] }
    var decoder: JSONDecoder { JSONDecoder() }

    /// The merged set of headers applied to the outgoing request:
    /// ``API/baseHeaders`` first, then ``Endpoint/headers`` (which wins).
    var allHeaders: HTTPHeaders {
        baseHeaders.merging(headers)
    }
}
