import Foundation

/// Translates an ``Endpoint`` and configuration into a ready-to-send
/// `URLRequest`.
///
/// Internal — exposed via the `@_spi(Testing)` SPI so the unit-test
/// target can verify request construction without spinning up a
/// transport. Production callers should always go through
/// ``NetworkManager``.
struct RequestBuilder: Sendable {
    /// Creates a stateless request builder.
    init() {}

    /// Builds a `URLRequest` for `endpoint`, merging `defaultHeaders`
    /// under the endpoint's own headers and falling back to
    /// `defaultTimeout` whenever the endpoint reports a non-positive
    /// timeout.
    func makeRequest<E: Endpoint>(
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
}

private extension RequestBuilder {
    /// Joins `base` and `path` while preserving any query string or
    /// fragment that `path` already carries — `URL.appendingPathComponent`
    /// percent-encodes `?` and `#`, silently destroying them.
    func resolvedURL(base: URL, path: String) throws -> URL {
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

    /// Splits a path-with-optional-query-and-fragment string into its
    /// constituent pieces so the path can be joined with the base URL
    /// without losing inline query items or anchors.
    func split(path: String) -> (path: String, query: String?, fragment: String?) {
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

    /// Routes the supplied ``HTTPTask`` shape into the request — body
    /// bytes, query items, additional headers, and / or multipart
    /// payload as appropriate. The default `Content-Type` for
    /// ``HTTPTask/plain`` is `application/json` so endpoints that don't
    /// specify one still receive a sensible value.
    func apply(task: HTTPTask, to request: inout URLRequest) throws {
        switch task {
        case .plain:
            request.setHeaderIfAbsent(
                HTTPHeader.Value.applicationJSON,
                forField: HTTPHeader.Field.contentType
            )

        case .parameters(let body, let encoding, let query):
            try encoding.apply(to: &request, body: body, query: query)

        case .parametersAndHeaders(let body, let encoding, let query, let additional):
            for (field, value) in additional {
                request.setValue(value, forHTTPHeaderField: field)
            }
            try encoding.apply(to: &request, body: body, query: query)

        case .multipart(let formData, let query):
            if let query, !query.isEmpty {
                try URLParameterEncoder().encode(query, into: &request)
            }
            request.httpBody = try formData.encode()
            // Multipart wins over any prior `Content-Type`, including the
            // form-urlencoded value `URLParameterEncoder` may have just
            // installed for the query-only branch above.
            request.setValue(
                formData.contentTypeHeaderValue,
                forHTTPHeaderField: HTTPHeader.Field.contentType
            )
        }
    }
}
