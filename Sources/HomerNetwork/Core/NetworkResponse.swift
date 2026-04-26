import Foundation

/// The decoded result of a successful HTTP request.
///
/// `value` carries the endpoint's `Response` type after JSON decoding;
/// `status`, `headers`, and `data` retain the raw response so callers can
/// inspect or persist them.
public struct NetworkResponse<Value: Sendable>: Sendable {
    public let value: Value
    public let status: HTTPStatus
    public let headers: HTTPHeaders
    public let data: Data

    public init(value: Value, status: HTTPStatus, headers: HTTPHeaders, data: Data) {
        self.value = value
        self.status = status
        self.headers = headers
        self.data = data
    }
}
