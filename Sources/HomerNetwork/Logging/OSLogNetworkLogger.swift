import Foundation
import os

/// A ``NetworkLogger`` backed by `os.Logger` that emits one line per
/// outgoing request and a status summary per response.
///
/// Privacy defaults:
/// - URL scheme/host/path are emitted in the clear; query values are
///   redacted unless their key is in `publicQueryKeys`.
/// - Header field names are public; values are redacted unless their
///   field name is in `publicHeaderFields`.
public struct OSLogNetworkLogger: NetworkLogger {
    private let logger: os.Logger
    private let publicHeaderFields: Set<String>
    private let sanitizer: URLSanitizer

    /// - Parameters:
    ///   - subsystem: Reverse-DNS subsystem identifier.
    ///   - category: Short category label, e.g. `"network"`.
    ///   - publicHeaderFields: Header field names whose *values* are safe
    ///     to emit in the clear. Comparison is case-insensitive.
    ///   - publicQueryKeys: Query item names whose *values* are safe to
    ///     emit in the clear. Comparison is case-insensitive. Default
    ///     redacts every query item.
    public init(
        subsystem: String,
        category: String = NetworkLoggerFormat.defaultCategory,
        publicHeaderFields: Set<String> = NetworkLoggerFormat.defaultPublicHeaderFields,
        publicQueryKeys: Set<String> = []
    ) {
        self.logger = os.Logger(subsystem: subsystem, category: category)
        self.publicHeaderFields = Set(publicHeaderFields.map { $0.lowercased() })
        self.sanitizer = URLSanitizer(publicQueryKeys: publicQueryKeys)
    }

    public func log(request: URLRequest) {
        let method = request.httpMethod ?? NetworkLoggerFormat.unknownPlaceholder
        let url = sanitizer.redact(request.url?.absoluteString ?? NetworkLoggerFormat.unknownPlaceholder)
        logger.info("\(NetworkLoggerFormat.requestPrefix, privacy: .public) \(method, privacy: .public) \(url, privacy: .public)")

        for (field, value) in request.allHTTPHeaderFields ?? [:] {
            if publicHeaderFields.contains(field.lowercased()) {
                logger.debug("  \(field, privacy: .public): \(value, privacy: .public)")
            } else {
                logger.debug("  \(field, privacy: .public): \(value, privacy: .private)")
            }
        }
    }

    public func log(response: HTTPURLResponse, data: Data) {
        let url = sanitizer.redact(response.url?.absoluteString ?? NetworkLoggerFormat.unknownPlaceholder)
        logger.info("\(NetworkLoggerFormat.responsePrefix, privacy: .public) \(response.statusCode, privacy: .public) \(url, privacy: .public) (\(data.count, privacy: .public)B)")
    }

    public func log(error: any Error) {
        logger.error("\(NetworkLoggerFormat.errorPrefix, privacy: .public) \(String(describing: error), privacy: .public)")
    }
}
