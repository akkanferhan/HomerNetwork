import Foundation

/// A typed HTTP endpoint.
///
/// Conform an enum or struct to `Endpoint` to describe a single request:
/// its base URL, path, method, body, and the type its JSON response
/// decodes into.
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
public protocol Endpoint: Sendable {
    /// The decoded type returned by ``NetworkClientProtocol/send(_:)``.
    associatedtype Response: Decodable & Sendable

    /// The scheme + host (and optional path prefix) for the endpoint.
    var baseURL: URL { get }

    /// Headers applied to the request before ``Endpoint/headers`` —
    /// typically API keys or User-Agent. Override on a single endpoint to
    /// share defaults across an enum's cases.
    var baseHeaders: HTTPHeaders { get }

    /// The default request timeout in seconds. Override on an endpoint to
    /// raise or lower the limit; falls back to
    /// ``NetworkClientConfiguration/defaultTimeout`` when zero.
    var timeout: TimeInterval { get }

    /// The path appended to ``Endpoint/baseURL``. Leading `/` recommended.
    var path: String { get }

    /// The HTTP verb.
    var httpMethod: HTTPMethod { get }

    /// The body / parameter / multipart shape of the request.
    var task: HTTPTask { get }

    /// Headers specific to this endpoint, merged on top of
    /// ``Endpoint/baseHeaders``.
    var headers: HTTPHeaders { get }

    /// The decoder used to parse the response body.
    var decoder: JSONDecoder { get }
}

public extension Endpoint {
    /// Empty by default — override to share API-key / User-Agent
    /// headers across an enum's cases.
    var baseHeaders: HTTPHeaders { [:] }

    /// Defaults to ``HomerNetworkDefaults/timeoutInterval`` (`30` s);
    /// override for endpoints that legitimately need a shorter or
    /// longer ceiling. Returning `0` defers to
    /// ``NetworkClientConfiguration/defaultTimeout``.
    var timeout: TimeInterval { HomerNetworkDefaults.timeoutInterval }

    /// Empty by default — override for headers specific to this single
    /// endpoint.
    var headers: HTTPHeaders { [:] }

    /// A fresh `JSONDecoder` with default settings. Override to
    /// configure key-decoding or date strategies.
    var decoder: JSONDecoder { JSONDecoder() }

    /// The merged set of headers applied to the outgoing request:
    /// ``Endpoint/baseHeaders`` first, then ``Endpoint/headers`` (which
    /// wins on conflict).
    var allHeaders: HTTPHeaders {
        baseHeaders.merging(headers)
    }
}
