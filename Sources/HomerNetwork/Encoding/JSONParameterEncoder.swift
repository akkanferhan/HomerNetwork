import Foundation

/// Encodes parameters as a JSON object in the request body.
struct JSONParameterEncoder: ParameterEncoder {
    /// Creates a stateless encoder.
    init() {}

    /// Serializes `parameters` to JSON and writes the bytes into
    /// `request.httpBody`, defaulting `Content-Type` to `application/json`.
    func encode(_ parameters: HTTPParameters, into request: inout URLRequest) throws {
        guard JSONSerialization.isValidJSONObject(parameters) else {
            throw NetworkEncodingError.jsonSerializationFailed(
                underlying: "value(s) not representable as JSON"
            )
        }
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            throw NetworkEncodingError.jsonSerializationFailed(
                underlying: String(describing: error)
            )
        }

        if request.value(forHTTPHeaderField: HTTPHeader.Field.contentType) == nil {
            request.setValue(
                HTTPHeader.Value.applicationJSON,
                forHTTPHeaderField: HTTPHeader.Field.contentType
            )
        }
    }
}
