import Foundation

/// Encodes parameters as a JSON object in the request body.
public struct JSONParameterEncoder: ParameterEncoder {
    public init() {}

    public func encode(_ parameters: Parameters, into request: inout URLRequest) throws {
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            throw NetworkEncodingError.jsonSerializationFailed
        }

        if request.value(forHTTPHeaderField: HTTPHeader.Field.contentType) == nil {
            request.setValue(
                HTTPHeader.Value.applicationJSON,
                forHTTPHeaderField: HTTPHeader.Field.contentType
            )
        }
    }
}
