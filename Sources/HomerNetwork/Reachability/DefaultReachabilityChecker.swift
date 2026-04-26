import Foundation
import HomerFoundation

/// The default ``ReachabilityProviding`` conformance used by
/// ``DefaultNetworkClient`` when no explicit checker is supplied.
///
/// Each call performs a one-shot `NWPathMonitor` query via
/// ``HomerFoundation/Reachability/currentStatus()``. There is no
/// long-lived monitor, no shared state, and no `start()`/`stop()`
/// lifecycle — making the type trivially `Sendable` and safe to use
/// as a default parameter value from any isolation domain.
///
/// > Performance: A fresh `NWPathMonitor` adds roughly 10–50ms of
/// > latency per request on a healthy device. For high-throughput
/// > clients prefer a long-lived ``HomerFoundation/Reachability``
/// > instance with ``HomerFoundation/Reachability/start()`` called —
/// > it conforms to ``ReachabilityProviding`` directly and reads from
/// > a cached observable property.
struct DefaultReachabilityChecker: ReachabilityProviding {
    /// Creates a new one-shot reachability checker.
    init() {}

    /// Performs a one-shot `NWPathMonitor` probe and returns `true` unless
    /// the path is `.unavailable`.
    func isReachable() async -> Bool {
        await Reachability.currentStatus() != .unavailable
    }
}
