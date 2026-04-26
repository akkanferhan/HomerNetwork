import Foundation
import HomerFoundation

/// Encodes parameters as `URLQueryItem`s appended to the request URL.
///
/// Existing query items already present on the URL are preserved; if a
/// caller supplies a key that the URL already has, the existing value is
/// replaced rather than duplicated.
struct URLParameterEncoder: ParameterEncoder {
    /// Creates a stateless encoder.
    init() {}

    /// Appends `parameters` as URL query items to `request.url`, replacing
    /// any existing entries with the same key.
    func encode(_ parameters: HTTPParameters, into request: inout URLRequest) throws {
        guard let url = request.url else { throw NetworkEncodingError.missingURL }
        guard !parameters.isEmpty else { return }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw NetworkEncodingError.missingURL
        }
        var queryItems = components.queryItems ?? []
        for (key, value) in parameters {
            queryItems.removeAll { $0.name == key }
            queryItems.append(URLQueryItem(name: key, value: Self.queryString(for: value)))
        }
        components.queryItems = queryItems
        guard let updatedURL = components.url else {
            throw NetworkEncodingError.missingURL
        }
        request.url = updatedURL

        if request.value(forHTTPHeaderField: HTTPHeader.Field.contentType) == nil {
            request.setValue(
                HTTPHeader.Value.applicationFormURLEncoded,
                forHTTPHeaderField: HTTPHeader.Field.contentType
            )
        }
    }

    /// Renders a parameter value as a query-string-safe string.
    ///
    /// `Bool` values become `"true"` / `"false"` (the JSON convention; if
    /// your API expects `"1"` / `"0"`, convert at the call site). `nil`
    /// values produce an empty string. All other values fall back to
    /// `String(describing:)`, which produces predictable output for
    /// `String`, `Int`, and `Double`; callers should avoid passing `Date`,
    /// `Data`, or custom types directly.
    static func queryString(for value: any Sendable) -> String {
        switch value {
        case let bool as Bool:
            return bool ? "true" : "false"
        case let optional as any AnyOptional where optional.isNil:
            return ""
        default:
            return String(describing: value)
        }
    }
}
