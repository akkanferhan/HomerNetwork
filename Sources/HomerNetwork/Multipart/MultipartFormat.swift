import Foundation

/// Wire-format constants for `multipart/form-data` per RFC 7578.
///
/// Internal — exists so ``MultipartFormData/encode()`` and the
/// `Content-Type` header value share a single source of truth for the
/// boundary token shape, the CRLF line break, and the disposition header
/// fragments.
enum MultipartFormat {
    /// CRLF line break required by RFC 7578.
    static let lineBreak = "\r\n"
    /// Two hyphens that introduce a boundary delimiter.
    static let boundaryDelimiter = "--"
    /// Prefix prepended to the random boundary suffix.
    static let boundaryPrefix = "Boundary-"
    /// `Content-Type` header value template; `%@` is replaced by the boundary.
    static let contentTypeTemplate = "multipart/form-data; boundary="
    /// `Content-Disposition` header field name.
    static let contentDispositionField = "Content-Disposition"
    /// `Content-Type` header field name (used for file parts).
    static let contentTypeField = "Content-Type"
    /// Disposition value common prefix.
    static let formDataDisposition = "form-data"
}
