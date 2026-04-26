import Foundation

/// Describes the request body, query parameters, and per-task headers for
/// an ``Endpoint``.
///
/// `HTTPTask` is intentionally an enum so endpoint authors can match the
/// shape of their request to one of a handful of well-defined cases.
public enum HTTPTask: Sendable {
    /// A request with neither body nor parameters.
    case plain

    /// A request whose parameters are encoded according to ``ParameterEncoding``.
    case parameters(
        body: HTTPParameters? = nil,
        encoding: ParameterEncoding,
        query: HTTPParameters? = nil
    )

    /// A request with parameters and one-shot additional headers merged on
    /// top of ``Endpoint/baseHeaders`` and ``Endpoint/headers``.
    case parametersAndHeaders(
        body: HTTPParameters? = nil,
        encoding: ParameterEncoding,
        query: HTTPParameters? = nil,
        additionalHeaders: HTTPHeaders
    )

    /// A `multipart/form-data` upload with optional URL query parameters.
    case multipart(
        MultipartFormData,
        query: HTTPParameters? = nil
    )
}
