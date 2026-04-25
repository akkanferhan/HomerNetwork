import Foundation

/// Shared display constants for ``NetworkLogger`` implementations.
///
/// Internal — both ``OSLogNetworkLogger`` and the ``HomerNetworkFoundation``
/// bridge consume the same prefixes and placeholders so log output stays
/// uniform across backends.
public enum NetworkLoggerFormat {
    /// Prefix prepended to every outgoing-request log line.
    public static let requestPrefix = "→"
    /// Prefix prepended to every incoming-response log line.
    public static let responsePrefix = "←"
    /// Prefix prepended to every error log line.
    public static let errorPrefix = "✕"
    /// Placeholder used when a method, URL, or category is missing.
    public static let unknownPlaceholder = "?"
    /// The default `os.Logger` category used by ``OSLogNetworkLogger``.
    public static let defaultCategory = "network"
    /// The default header field names whose values are safe to log in the clear.
    public static let defaultPublicHeaderFields: Set<String> = [
        HTTPHeader.Field.contentType,
        HTTPHeader.Field.accept
    ]
}
