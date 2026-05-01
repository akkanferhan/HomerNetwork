import Foundation

/// A type that asynchronously reports whether the device has a usable
/// network path.
///
/// ``NetworkManager`` consults its injected ``ConnectivityProbing`` once
/// per request, immediately before any transport activity. When the
/// probe returns `false` the client throws ``NetworkError/offline``
/// without invoking the transport — saving bandwidth, battery, and
/// avoiding spurious errors that would otherwise surface as
/// ``NetworkError/transport(_:)``.
///
/// > Note: The check is a best-effort pre-flight. A brief connectivity
/// > loss between the gate and the actual transport hop can still
/// > produce a ``NetworkError/transport(_:)`` error; the gate is not a
/// > guarantee that the request will succeed if it gets past it.
///
/// ## Naming
///
/// In `0.6.0` this protocol was renamed from `ReachabilityProviding` to
/// avoid a collision with `HomerFoundation 0.5.0`'s observable
/// `ReachabilityProviding` protocol — which describes a long-lived,
/// `@MainActor`, ``Observable`` connectivity *provider* (with `start()` /
/// `stop()` and a published `isConnected` flag) rather than the
/// `Sendable`, async, one-shot **probe** modelled here. A deprecated
/// typealias (``ReachabilityProviding``) is provided for one minor cycle
/// of source compatibility; new code should refer to ``ConnectivityProbing``.
///
/// ## Defaults and integrations
///
/// When ``NetworkClientConfiguration/init(session:defaultHeaders:defaultTimeout:logger:validateHTTPStatus:reachability:retryPolicy:)``
/// receives `nil` for `reachability`, an internal one-shot probe backed
/// by `HomerFoundation.Reachability.currentStatus()` is used. To
/// integrate with a long-lived observable connectivity store, inject a
/// `HomerFoundation.Reachability` instance directly — it conforms to
/// ``ConnectivityProbing`` out of the box (see
/// ``Reachability+ConnectivityProbing``).
///
/// > Important: Implementations are called on the request's hot path
/// > and must be cheap (sub-100ms is the design target). A slow probe
/// > directly inflates request latency.
public protocol ConnectivityProbing: Sendable {
    /// Returns `true` when the device currently has a usable network
    /// path.
    func isReachable() async -> Bool
}

/// Source-compatibility alias for the protocol's pre-`0.6.0` name. New
/// code should refer to ``ConnectivityProbing`` directly so that the
/// HomerFoundation observable ``ReachabilityProviding`` and HomerNetwork's
/// async probe stay unambiguous when both modules are imported.
@available(*, deprecated, renamed: "ConnectivityProbing", message: "Renamed in 0.6.0 to disambiguate from HomerFoundation's observable ReachabilityProviding protocol.")
public typealias ReachabilityProviding = ConnectivityProbing
