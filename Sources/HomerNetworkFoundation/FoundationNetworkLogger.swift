import Foundation
import HomerNetwork
import HomerFoundation

/// A ``NetworkLogger`` that forwards to a ``HomerFoundation/Log`` channel.
///
/// Available in the `HomerNetworkFoundation` product when you already use
/// HomerFoundation for logging and want a single unified signal.
///
/// Like ``OSLogNetworkLogger``, query items are redacted by default
/// before the URL reaches the log channel; supply `publicQueryKeys` to
/// allowlist names whose values are safe to log.
public struct FoundationNetworkLogger: NetworkLogger {
    private let log: Log
    private let sanitizer: URLSanitizer

    /// - Parameters:
    ///   - log: The HomerFoundation log channel to forward into.
    ///     Defaults to ``HomerFoundation/Log/default``.
    ///   - publicQueryKeys: Query item names whose values are safe to log
    ///     in the clear. Comparison is case-insensitive.
    public init(log: Log = .default, publicQueryKeys: Set<String> = []) {
        self.log = log
        self.sanitizer = URLSanitizer(publicQueryKeys: publicQueryKeys)
    }

    public func log(request: URLRequest) {
        let method = request.httpMethod ?? NetworkLoggerFormat.unknownPlaceholder
        let url = sanitizer.redact(request.url?.absoluteString ?? NetworkLoggerFormat.unknownPlaceholder)
        log.info("\(NetworkLoggerFormat.requestPrefix) \(method) \(url)")
    }

    public func log(response: HTTPURLResponse, data: Data) {
        let url = sanitizer.redact(response.url?.absoluteString ?? NetworkLoggerFormat.unknownPlaceholder)
        log.info("\(NetworkLoggerFormat.responsePrefix) \(response.statusCode) \(url) (\(data.count)B)")
    }

    public func log(error: any Error) {
        log.error("\(NetworkLoggerFormat.errorPrefix) \(String(describing: error))")
    }
}
