import Foundation

/// Errors thrown while preparing the body or query string of a request.
///
/// This is distinct from Swift's standard library `EncodingError` (which is
/// raised by `Encoder` implementations); it covers failures specific to
/// turning ``HTTPParameters`` and multipart payloads into a `URLRequest`.
public enum NetworkEncodingError: Error, Sendable, Equatable {
    /// The request had no URL to attach query items to.
    case missingURL
    /// JSON serialization failed for the supplied parameters; the
    /// associated string carries the underlying `JSONSerialization` error
    /// description so callers can diagnose which value caused the failure.
    case jsonSerializationFailed(underlying: String)
    /// Multipart body could not be assembled.
    case multipartFailure(String)
}
