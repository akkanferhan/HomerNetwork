import Foundation
import HomerNetwork
import HomerFoundation

/// A ``NetworkLogger`` that forwards to a ``HomerFoundation/Log`` channel.
///
/// Available in the `HomerNetworkFoundation` product when you already use
/// HomerFoundation for logging and want a single unified signal.
public struct FoundationNetworkLogger: NetworkLogger {
    private let log: Log

    /// - Parameter log: The HomerFoundation log channel to forward into.
    ///   Defaults to ``HomerFoundation/Log/default``.
    public init(log: Log = .default) {
        self.log = log
    }

    public func log(request: URLRequest) {
        let method = request.httpMethod ?? NetworkLoggerFormat.unknownPlaceholder
        let url = request.url?.absoluteString ?? NetworkLoggerFormat.unknownPlaceholder
        log.info("\(NetworkLoggerFormat.requestPrefix) \(method) \(url)")
    }

    public func log(response: HTTPURLResponse, data: Data) {
        let url = response.url?.absoluteString ?? NetworkLoggerFormat.unknownPlaceholder
        log.info("\(NetworkLoggerFormat.responsePrefix) \(response.statusCode) \(url) (\(data.count)B)")
    }

    public func log(error: any Error) {
        log.error("\(NetworkLoggerFormat.errorPrefix) \(String(describing: error))")
    }
}
