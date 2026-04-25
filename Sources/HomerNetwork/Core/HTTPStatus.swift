import Foundation

/// The half-open ranges that map raw HTTP status codes onto ``StatusCodeType``.
///
/// Internal — exposed only so ``StatusCodeType/init(statusCode:)`` and
/// downstream tests share a single source of truth for the boundaries.
enum HTTPStatusRange {
    static let informational = 100..<200
    static let success = 200..<300
    static let redirection = 300..<400
    static let clientError = 400..<500
    static let serverError = 500..<600
}

/// A semantic categorization of an HTTP status code.
public enum StatusCodeType: Sendable, Hashable {
    case informational
    case success
    case redirection
    case clientError
    case serverError
    case unrecognized

    public init(statusCode: Int) {
        switch statusCode {
        case HTTPStatusRange.informational: self = .informational
        case HTTPStatusRange.success:       self = .success
        case HTTPStatusRange.redirection:   self = .redirection
        case HTTPStatusRange.clientError:   self = .clientError
        case HTTPStatusRange.serverError:   self = .serverError
        default:                            self = .unrecognized
        }
    }
}

/// HTTP response status combining the raw code and its semantic category.
public struct HTTPStatus: Sendable, Hashable {
    public let statusCode: Int
    public let statusType: StatusCodeType

    public init(statusCode: Int) {
        self.statusCode = statusCode
        self.statusType = StatusCodeType(statusCode: statusCode)
    }

    public init(httpURLResponse: HTTPURLResponse) {
        self.init(statusCode: httpURLResponse.statusCode)
    }

    /// `true` when the status code falls in the 2xx range.
    public var isSuccess: Bool { statusType == .success }
}
