import Foundation

/// Strips or redacts query items that may contain credentials before a URL
/// is emitted to a log channel.
///
/// Internal — ``FoundationNetworkLogger`` consumes ``redact(_:)`` so it
/// has a single source of truth for which query keys are safe to log in
/// the clear. Third-party ``NetworkLogger`` conformers should perform
/// their own sanitization.
struct URLSanitizer: Sendable {
    /// Replacement string used in place of redacted query values.
    /// Uses only URL-safe characters so it survives percent-encoding round-trips.
    static let redactedToken = "REDACTED"

    private let publicQueryKeys: Set<String>

    /// - Parameter publicQueryKeys: Lower-cased names of query items whose
    ///   values are safe to log. Anything else is replaced by
    ///   ``URLSanitizer/redactedToken``.
    init(publicQueryKeys: Set<String> = []) {
        self.publicQueryKeys = Set(publicQueryKeys.map { $0.lowercased() })
    }

    /// Returns a copy of `urlString` whose query values are redacted unless
    /// their key is in the allowlist. Fragment is dropped entirely.
    func redact(_ urlString: String) -> String {
        guard var components = URLComponents(string: urlString) else { return urlString }
        if let items = components.queryItems {
            components.queryItems = items.map { item in
                if publicQueryKeys.contains(item.name.lowercased()) {
                    return item
                }
                return URLQueryItem(name: item.name, value: Self.redactedToken)
            }
        }
        components.fragment = nil
        return components.string ?? urlString
    }
}
