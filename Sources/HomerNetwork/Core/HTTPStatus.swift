import Foundation

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
        case 100..<200: self = .informational
        case 200..<300: self = .success
        case 300..<400: self = .redirection
        case 400..<500: self = .clientError
        case 500..<600: self = .serverError
        default:        self = .unrecognized
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
