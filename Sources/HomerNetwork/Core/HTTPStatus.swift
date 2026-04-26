import Foundation

/// A semantic categorization of an HTTP status code.
enum StatusCodeType: Sendable, Hashable {
    case informational
    case success
    case redirection
    case clientError
    case serverError
    case unrecognized

    /// Buckets a raw HTTP status code into its semantic ``StatusCodeType``.
    /// Codes outside the 100–599 range resolve to ``unrecognized``.
    init(statusCode: Int) {
        switch statusCode {
        case Range.informational: self = .informational
        case Range.success:       self = .success
        case Range.redirection:   self = .redirection
        case Range.clientError:   self = .clientError
        case Range.serverError:   self = .serverError
        default:                  self = .unrecognized
        }
    }

    /// Half-open ranges that map raw HTTP status codes onto ``StatusCodeType``.
    private enum Range {
        static let informational = 100..<200
        static let success = 200..<300
        static let redirection = 300..<400
        static let clientError = 400..<500
        static let serverError = 500..<600
    }
}

/// HTTP response status combining the raw code and its semantic category.
public struct HTTPStatus: Sendable, Hashable {
    /// The raw HTTP status code as reported by the server.
    public let statusCode: Int
    /// The ``StatusCodeType`` bucket derived from ``statusCode``.
    let statusType: StatusCodeType

    /// Creates a status from a raw code and computes its ``statusType``.
    public init(statusCode: Int) {
        self.statusCode = statusCode
        self.statusType = StatusCodeType(statusCode: statusCode)
    }

    /// Creates a status by reading `statusCode` from an `HTTPURLResponse`.
    public init(httpURLResponse: HTTPURLResponse) {
        self.init(statusCode: httpURLResponse.statusCode)
    }

    /// `true` when the status code falls in the 1xx range.
    public var isInformational: Bool { statusType == .informational }
    /// `true` when the status code falls in the 2xx range.
    public var isSuccess: Bool { statusType == .success }
    /// `true` when the status code falls in the 3xx range.
    public var isRedirection: Bool { statusType == .redirection }
    /// `true` when the status code falls in the 4xx range.
    public var isClientError: Bool { statusType == .clientError }
    /// `true` when the status code falls in the 5xx range.
    public var isServerError: Bool { statusType == .serverError }
}
