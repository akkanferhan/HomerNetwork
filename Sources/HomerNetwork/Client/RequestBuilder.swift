import Foundation

/// Translates an ``Endpoint`` and configuration into a ready-to-send `URLRequest`.
///
/// Internal — exposed via `@_spi(Testing)` so the test target
/// can verify request construction without spinning up a transport.
@_spi(Testing)
public struct RequestBuilder: Sendable {
    /// Creates a stateless request builder.
    public init() {}

    /// Builds a `URLRequest` for `endpoint`, merging `defaultHeaders` under
    /// the endpoint's own headers and falling back to `defaultTimeout`
    /// whenever the endpoint reports a non-positive timeout.
    public func makeRequest<E: Endpoint>(
        for endpoint: E,
        defaultHeaders: HTTPHeaders,
        defaultTimeout: TimeInterval
    ) throws -> URLRequest {
        let url = try resolvedURL(base: endpoint.baseURL, path: endpoint.path)
        let timeout = endpoint.timeout > 0 ? endpoint.timeout : defaultTimeout

        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: timeout
        )
        request.httpMethod = endpoint.httpMethod.rawValue

        let merged = defaultHeaders
            .merging(endpoint.allHeaders)
        request.allHTTPHeaderFields = merged.dictionary

        try apply(task: endpoint.task, to: &request)
        return request
    }

    /// Joins `base` and `path` while preserving any query string or
    /// fragment that `path` already carries — `URL.appendingPathComponent`
    /// percent-encodes `?` and `#`, silently destroying them.
    private func resolvedURL(base: URL, path: String) throws -> URL {
        guard var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidRequest
        }

        let (rawPath, query, fragment) = split(path: path)

        if !rawPath.isEmpty {
            let basePath = components.path
            let needsSlash = !basePath.hasSuffix("/") && !rawPath.hasPrefix("/") && !basePath.isEmpty
            components.path = basePath + (needsSlash ? "/" : "") + rawPath
        }

        if let query, !query.isEmpty {
            let existing = components.queryItems ?? []
            let inherited = URLComponents(string: "?\(query)")?.queryItems ?? []
            components.queryItems = existing + inherited
        }

        if let fragment {
            components.fragment = fragment
        }

        guard let url = components.url else {
            throw NetworkError.invalidRequest
        }
        return url
    }

    /// Splits a path-with-optional-query-and-fragment string into its parts.
    private func split(path: String) -> (path: String, query: String?, fragment: String?) {
        var rest = path
        var fragment: String?
        if let hashIndex = rest.firstIndex(of: "#") {
            fragment = String(rest[rest.index(after: hashIndex)...])
            rest = String(rest[..<hashIndex])
        }
        var query: String?
        if let qIndex = rest.firstIndex(of: "?") {
            query = String(rest[rest.index(after: qIndex)...])
            rest = String(rest[..<qIndex])
        }
        return (rest, query, fragment)
    }

    private func apply(task: HTTPTask, to request: inout URLRequest) throws {
        switch task {
        case .plain:
            if request.value(forHTTPHeaderField: HTTPHeader.Field.contentType) == nil {
                request.setValue(
                    HTTPHeader.Value.applicationJSON,
                    forHTTPHeaderField: HTTPHeader.Field.contentType
                )
            }

        case .parameters(let body, let encoding, let query):
            try encoding.apply(to: &request, body: body, query: query)

        case .parametersAndHeaders(let body, let encoding, let query, let additional):
            for entry in additional {
                request.setValue(entry.value, forHTTPHeaderField: entry.field)
            }
            try encoding.apply(to: &request, body: body, query: query)

        case .multipart(let formData, let query):
            if let query, !query.isEmpty {
                try URLParameterEncoder().encode(query, into: &request)
            }
            request.httpBody = try formData.encode()
            request.setValue(
                formData.contentTypeHeaderValue,
                forHTTPHeaderField: HTTPHeader.Field.contentType
            )
        }
    }
}
