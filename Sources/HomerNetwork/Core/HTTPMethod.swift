import Foundation

/// HTTP request methods supported by ``NetworkClient``.
public enum HTTPMethod: String, Sendable, Hashable {
    /// `GET` — retrieve a representation of the target resource (RFC 9110 §9.3.1).
    case get = "GET"
    /// `POST` — submit data to be processed by the target resource (RFC 9110 §9.3.3).
    case post = "POST"
    /// `PUT` — replace the target resource with the request payload (RFC 9110 §9.3.4).
    case put = "PUT"
    /// `PATCH` — apply a partial modification to the target resource (RFC 5789).
    case patch = "PATCH"
    /// `DELETE` — remove the target resource (RFC 9110 §9.3.5).
    case delete = "DELETE"
    /// `HEAD` — same semantics as `GET` but without a response body (RFC 9110 §9.3.2).
    case head = "HEAD"

    /// `true` when the method is defined as idempotent by RFC 9110 §9.2.2 —
    /// safe to retry without observable additional side effects.
    ///
    /// Used by ``NetworkManager`` to gate automatic retries: only
    /// idempotent verbs are reissued on transient failures, so a `POST`
    /// that times out after the server already accepted it doesn't get
    /// duplicated.
    public var isIdempotent: Bool {
        switch self {
        case .get, .head, .put, .delete:
            return true
        case .post, .patch:
            return false
        }
    }
}
