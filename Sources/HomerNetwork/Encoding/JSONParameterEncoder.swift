import Foundation

/// Encodes parameters as a JSON object in the request body.
///
/// Internal — exposed indirectly through ``ParameterEncoding/json``.
/// Independently constructible encoders were dropped from the public
/// surface in `0.4.0`; ``ParameterEncoding/custom(_:)`` remains the
/// extension point for app-specific encoding strategies.
struct JSONParameterEncoder: ParameterEncoder {
    /// Creates a stateless encoder.
    init() {}

    /// Serializes `parameters` to JSON and writes the bytes into
    /// `request.httpBody`, defaulting `Content-Type` to
    /// `application/json` when the request does not already declare one.
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

        request.setHeaderIfAbsent(
            HTTPHeader.Value.applicationJSON,
            forField: HTTPHeader.Field.contentType
        )
    }
}
