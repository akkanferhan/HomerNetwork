import Foundation

/// The decoded result of a successful HTTP request.
///
/// `value` carries the endpoint's `Response` type after JSON decoding;
/// `status`, `headers`, and `data` retain the raw response so callers can
/// inspect or persist them.
public struct NetworkResponse<Value: Sendable>: Sendable {
    /// The decoded payload produced by the endpoint's `decoder`.
    public let value: Value
    /// The HTTP status reported by the server.
    public let status: HTTPStatus
    /// The response headers, preserving original field-name casing.
    public let headers: HTTPHeaders
    /// The raw response body as returned by the transport.
    public let data: Data

    /// Creates a response from a decoded value plus its raw HTTP context.
    public init(value: Value, status: HTTPStatus, headers: HTTPHeaders, data: Data) {
        self.value = value
        self.status = status
        self.headers = headers
        self.data = data
    }
}
