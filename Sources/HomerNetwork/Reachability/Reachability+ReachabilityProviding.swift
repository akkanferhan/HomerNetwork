import Foundation
import HomerFoundation

/// Lets a long-lived ``HomerFoundation/Reachability`` instance be
/// injected into ``DefaultNetworkClient`` directly, sharing one
/// `NWPathMonitor` across the entire app.
///
/// The reading is taken from the observable
/// ``HomerFoundation/Reachability/isConnected`` snapshot, so callers
/// must have invoked ``HomerFoundation/Reachability/start()`` for it
/// to reflect live state. A freshly constructed instance reports
/// `false` until the first path update arrives.
extension Reachability: ReachabilityProviding {
    /// Reads the cached ``HomerFoundation/Reachability/isConnected`` flag
    /// on the main actor; no fresh probe is performed.
    public nonisolated func isReachable() async -> Bool {
        await MainActor.run { self.isConnected }
    }
}
