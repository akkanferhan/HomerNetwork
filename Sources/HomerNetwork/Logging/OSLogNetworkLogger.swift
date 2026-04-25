import Foundation
import os

/// A ``NetworkLogger`` backed by `os.Logger` that emits one line per
/// outgoing request and a status summary per response.
///
/// The output is privacy-safe by default: URLs and methods are public,
/// header field values are redacted unless the field name appears in the
/// allowlist passed at construction time.
public struct OSLogNetworkLogger: NetworkLogger {
    private let logger: os.Logger
    private let publicHeaderFields: Set<String>

    /// - Parameters:
    ///   - subsystem: Reverse-DNS subsystem identifier.
    ///   - category: Short category label, e.g. `"network"`.
    ///   - publicHeaderFields: Header field names whose *values* should be
    ///     emitted in the clear. Comparison is case-insensitive.
    public init(
        subsystem: String,
        category: String = NetworkLoggerFormat.defaultCategory,
        publicHeaderFields: Set<String> = NetworkLoggerFormat.defaultPublicHeaderFields
    ) {
        self.logger = os.Logger(subsystem: subsystem, category: category)
        self.publicHeaderFields = Set(publicHeaderFields.map { $0.lowercased() })
    }

    public func log(request: URLRequest) {
        let method = request.httpMethod ?? NetworkLoggerFormat.unknownPlaceholder
        let url = request.url?.absoluteString ?? NetworkLoggerFormat.unknownPlaceholder
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
        let url = response.url?.absoluteString ?? NetworkLoggerFormat.unknownPlaceholder
        logger.info("\(NetworkLoggerFormat.responsePrefix, privacy: .public) \(response.statusCode, privacy: .public) \(url, privacy: .public) (\(data.count, privacy: .public)B)")
    }

    public func log(error: any Error) {
        logger.error("\(NetworkLoggerFormat.errorPrefix, privacy: .public) \(String(describing: error), privacy: .public)")
    }
}
