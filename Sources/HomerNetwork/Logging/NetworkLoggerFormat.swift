import Foundation

/// Shared display constants for ``NetworkLogger`` implementations.
///
/// Internal — ``FoundationNetworkLogger`` and any third-party
/// `NetworkLogger` conformer that lives in this module consume the same
/// prefixes and placeholders so log output stays uniform across
/// implementations.
enum NetworkLoggerFormat {
    /// Prefix prepended to every outgoing-request log line.
    static let requestPrefix = "→"
    /// Prefix prepended to every incoming-response log line.
    static let responsePrefix = "←"
    /// Prefix prepended to every error log line.
    static let errorPrefix = "✕"
    /// Placeholder used when a method, URL, or category is missing.
    static let unknownPlaceholder = "?"
    /// Replacement emitted in place of a non-allowlisted header value.
    static let redactedHeaderValue = "<redacted>"

    /// Returns a single header log line for `field: value`, redacting the
    /// value when `field` (compared case-insensitively) is not in
    /// `publicFields`.
    ///
    /// `publicFields` must already be lowercased — the normalisation is the
    /// caller's responsibility so this remains a pure, dependency-free helper.
    static func headerLine(field: String, value: String, publicFields: Set<String>) -> String {
        let emittedValue = publicFields.contains(field.lowercased()) ? value : redactedHeaderValue
        return "  \(field): \(emittedValue)"
    }
}
