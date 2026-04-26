import Foundation

/// The body/query encoding strategy used by an ``HTTPTask``.
public enum ParameterEncoding: Sendable {
    /// Encode parameters as URL query items, regardless of HTTP method.
    case url
    /// Encode parameters as a JSON body.
    case json
    /// Encode `body` parameters as JSON and `query` parameters as URL items.
    case urlAndJSON
    /// Use the supplied raw body bytes verbatim. Caller is responsible for
    /// the Content-Type header.
    case rawBody(Data)
    /// Delegate to a user-supplied encoder.
    case custom(any ParameterEncoder)
}

extension ParameterEncoding {
    /// Applies the strategy to the given request.
    ///
    /// - Parameters:
    ///   - request: The request to mutate.
    ///   - body: Parameters to encode into the body (JSON, raw, custom).
    ///   - query: Parameters to encode as URL query items.
    func apply(
        to request: inout URLRequest,
        body: Parameters?,
        query: Parameters?
    ) throws {
        switch self {
        case .url:
            if let query, !query.isEmpty {
                try URLParameterEncoder().encode(query, into: &request)
            } else if let body, !body.isEmpty {
                try URLParameterEncoder().encode(body, into: &request)
            }

        case .json:
            if let body, !body.isEmpty {
                try JSONParameterEncoder().encode(body, into: &request)
            }

        case .urlAndJSON:
            if let query, !query.isEmpty {
                try URLParameterEncoder().encode(query, into: &request)
            }
            if let body, !body.isEmpty {
                try JSONParameterEncoder().encode(body, into: &request)
            }

        case .rawBody(let data):
            request.httpBody = data

        case .custom(let encoder):
            if let body, !body.isEmpty {
                try encoder.encode(body, into: &request)
            }
        }
    }
}
