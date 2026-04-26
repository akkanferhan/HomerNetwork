import Foundation
import HomerFoundation

/// A ``NetworkLogger`` that forwards to a ``HomerFoundation/Log`` channel.
///
/// `Log` is itself backed by `os.Logger`, so this logger participates in
/// the unified Apple log store while also flowing through the Homer
/// suite's shared logging signal.
///
/// Privacy defaults:
/// - URL scheme/host/path are emitted in the clear; query values are
///   redacted unless their key is in `publicQueryKeys`.
/// - Header field names are emitted at the `.debug` level only when
///   `publicHeaderFields` is non-empty; values are kept private unless
///   their field name is in the allowlist.
public struct FoundationNetworkLogger: NetworkLogger {
    private let log: Log
    private let sanitizer: URLSanitizer
    private let publicHeaderFields: Set<String>

    /// - Parameters:
    ///   - log: The HomerFoundation log channel to forward into.
    ///     Defaults to ``HomerFoundation/Log/default``.
    ///   - publicHeaderFields: Header field names whose *values* are safe
    ///     to emit at the debug level. Comparison is case-insensitive.
    ///     An empty set (the default) suppresses header emission entirely.
    ///   - publicQueryKeys: Query item names whose *values* are safe to
    ///     emit in the clear. Comparison is case-insensitive. Default
    ///     redacts every query item.
    public init(
        log: Log = .default,
        publicHeaderFields: Set<String> = [],
        publicQueryKeys: Set<String> = []
    ) {
        self.log = log
        self.sanitizer = URLSanitizer(publicQueryKeys: publicQueryKeys)
        self.publicHeaderFields = Set(publicHeaderFields.map { $0.lowercased() })
    }

    /// Emits a single `info` line per request and one `debug` line per
    /// header (values redacted unless their field is in `publicHeaderFields`).
    public func log(request: URLRequest) {
        let method = request.httpMethod ?? NetworkLoggerFormat.unknownPlaceholder
        let url = sanitizer.redact(request.url?.absoluteString ?? NetworkLoggerFormat.unknownPlaceholder)
        log.info("\(NetworkLoggerFormat.requestPrefix) \(method) \(url)")

        guard !publicHeaderFields.isEmpty else { return }
        for (field, value) in request.allHTTPHeaderFields ?? [:] {
            log.debug(NetworkLoggerFormat.headerLine(field: field, value: value, publicFields: publicHeaderFields))
        }
    }

    /// Emits a single `info` line summarizing the status, sanitized URL,
    /// and body byte count.
    public func log(response: HTTPURLResponse, data: Data) {
        let url = sanitizer.redact(response.url?.absoluteString ?? NetworkLoggerFormat.unknownPlaceholder)
        log.info("\(NetworkLoggerFormat.responsePrefix) \(response.statusCode) \(url) (\(data.count)B)")
    }

    /// Emits a single `error` line carrying `String(describing: error)`.
    public func log(error: any Error) {
        log.error("\(NetworkLoggerFormat.errorPrefix) \(String(describing: error))")
    }
}
