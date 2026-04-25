import Foundation

/// Errors thrown while preparing the body or query string of a request.
///
/// This is distinct from Swift's standard library `EncodingError` (which is
/// raised by `Encoder` implementations); it covers failures specific to
/// turning ``Parameters`` and multipart payloads into a `URLRequest`.
public enum NetworkEncodingError: Error, Sendable, Equatable {
    /// The request had no URL to attach query items to.
    case missingURL
    /// The supplied parameters could not be serialized.
    case invalidParameters
    /// JSON serialization failed for the supplied parameters.
    case jsonSerializationFailed
    /// Multipart body could not be assembled.
    case multipartFailure(String)
}
