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
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"
        log.info("→ \(method) \(url)")
    }

    public func log(response: HTTPURLResponse, data: Data) {
        let url = response.url?.absoluteString ?? "?"
        log.info("← \(response.statusCode) \(url) (\(data.count)B)")
    }

    public func log(error: any Error) {
        log.error("✕ \(String(describing: error))")
    }
}
