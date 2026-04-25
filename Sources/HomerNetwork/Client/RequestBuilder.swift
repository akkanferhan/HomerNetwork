import Foundation

/// Translates an ``Endpoint`` and configuration into a ready-to-send `URLRequest`.
///
/// Internal — exposed via `@_spi(HomerNetworkInternal)` so the test target
/// can verify request construction without spinning up a transport.
@_spi(HomerNetworkInternal)
public struct RequestBuilder: Sendable {
    public init() {}

    public func makeRequest<E: Endpoint>(
        for endpoint: E,
        defaultHeaders: HTTPHeaders,
        defaultTimeout: TimeInterval
    ) throws -> URLRequest {
        let url = endpoint.baseURL.appendingPathComponent(endpoint.path)
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
            request.httpBody = formData.encode()
            request.setValue(
                formData.contentTypeHeaderValue,
                forHTTPHeaderField: HTTPHeader.Field.contentType
            )
        }
    }
}
