import Foundation

/// Errors thrown by ``NetworkClient`` and its supporting machinery.
public enum NetworkError: Error, Sendable {
    /// The request failed to build (e.g. malformed URL).
    case invalidRequest

    /// Parameter or body encoding failed.
    case encoding(NetworkEncodingError)

    /// The transport layer reported an error (URLSession, connectivity).
    case transport(any Error & Sendable)

    /// The server responded with a non-2xx status. The raw body is retained
    /// so callers can decode an error envelope if they want.
    ///
    /// > Warning: `data` is the unfiltered response body — for many APIs
    /// > it contains sensitive information (PII, tokens, account state).
    /// > Do not log, attach to crash reports, or forward `data` to
    /// > telemetry without redacting first.
    case http(status: HTTPStatus, data: Data)

    /// The response could not be decoded into the endpoint's `Response` type.
    ///
    /// > Warning: `data` is the unfiltered response body and may contain
    /// > sensitive information. See ``NetworkError/http(status:data:)``
    /// > for handling guidance.
    case decoding(any Error & Sendable, data: Data)

    /// The response was missing or not an `HTTPURLResponse`.
    case invalidResponse

    /// The request was cancelled — either by `Task.cancel()` propagating
    /// down or by `URLSession` returning `URLError.cancelled`.
    case cancelled

    /// The injected ``ConnectivityProbing`` reported no usable network
    /// path before the request was attempted. Thrown by
    /// ``NetworkManager`` ahead of any transport hop, so retries are
    /// safe and idempotent — nothing was sent.
    case offline
}

extension NetworkError: CustomStringConvertible {
    /// Returns a non-localized debug description suitable for logs.
    public var description: String {
        switch self {
        case .invalidRequest:
            return "NetworkError.invalidRequest"
        case .encoding(let error):
            return "NetworkError.encoding(\(error))"
        case .transport(let error):
            return "NetworkError.transport(\(error))"
        case .http(let status, _):
            return "NetworkError.http(status: \(status.statusCode))"
        case .decoding(let error, _):
            return "NetworkError.decoding(\(error))"
        case .invalidResponse:
            return "NetworkError.invalidResponse"
        case .cancelled:
            return "NetworkError.cancelled"
        case .offline:
            return "NetworkError.offline"
        }
    }
}
