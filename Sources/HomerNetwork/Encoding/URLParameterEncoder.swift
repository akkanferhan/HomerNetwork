import Foundation

/// Encodes parameters as `URLQueryItem`s appended to the request URL.
public struct URLParameterEncoder: ParameterEncoder {
    public init() {}

    public func encode(_ parameters: Parameters, into request: inout URLRequest) throws {
        guard let url = request.url else { throw NetworkEncodingError.missingURL }
        guard !parameters.isEmpty else { return }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        for (key, value) in parameters {
            queryItems.append(URLQueryItem(name: key, value: String(describing: value)))
        }
        components?.queryItems = queryItems
        request.url = components?.url

        if request.value(forHTTPHeaderField: HTTPHeader.Field.contentType) == nil {
            request.setValue(
                HTTPHeader.Value.applicationFormURLEncoded,
                forHTTPHeaderField: HTTPHeader.Field.contentType
            )
        }
    }
}
