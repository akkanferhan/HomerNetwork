import Foundation
import HomerFoundation

/// The default ``ConnectivityProbing`` conformance used by
/// ``NetworkManager`` when no explicit probe is supplied.
///
/// Each call performs a one-shot `NWPathMonitor` query via
/// `HomerFoundation.Reachability.currentStatus()`. There is no
/// long-lived monitor, no shared state, and no `start()`/`stop()`
/// lifecycle — making the type trivially `Sendable` and safe to use as
/// a default parameter value from any isolation domain.
///
/// > Performance: A fresh `NWPathMonitor` adds roughly 10–50 ms of
/// > latency per request on a healthy device. For high-throughput
/// > clients prefer a long-lived `HomerFoundation.Reachability`
/// > instance with `start()` already called — it conforms to
/// > ``ConnectivityProbing`` directly and reads from a cached
/// > observable property (see ``Reachability+ConnectivityProbing``).
public struct DefaultConnectivityProbe: ConnectivityProbing {
    /// Creates a new one-shot connectivity probe.
    public init() {}

    /// Performs a one-shot `NWPathMonitor` probe and returns `true`
    /// unless the path is `.unavailable`.
    public func isReachable() async -> Bool {
        await Reachability.currentStatus() != .unavailable
    }
}

/// Source-compatibility alias for the type's pre-`0.6.0` name.
@available(*, deprecated, renamed: "DefaultConnectivityProbe", message: "Renamed in 0.6.0 alongside the protocol rename ReachabilityProviding → ConnectivityProbing.")
public typealias DefaultReachabilityChecker = DefaultConnectivityProbe
