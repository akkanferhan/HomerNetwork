import Foundation
import HomerFoundation

/// Lets a long-lived `HomerFoundation.Reachability` instance be injected
/// into ``NetworkManager`` directly, sharing one `NWPathMonitor` across
/// the entire app.
///
/// The reading is taken from the observable
/// `HomerFoundation.Reachability.isConnected` snapshot, so callers must
/// have invoked `Reachability.start()` for it to reflect live state. A
/// freshly constructed instance reports `false` until the first path
/// update arrives.
///
/// ```swift
/// let reachability = Reachability()
/// reachability.start()
/// let config = NetworkClientConfiguration(reachability: reachability)
/// let client = NetworkManager(configuration: config)
/// ```
extension Reachability: ConnectivityProbing {
    /// Reads the cached `Reachability.isConnected` flag on the main
    /// actor; no fresh probe is performed.
    public nonisolated func isReachable() async -> Bool {
        await MainActor.run { self.isConnected }
    }
}
