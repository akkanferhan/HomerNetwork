import Foundation

/// A type that asynchronously reports whether the device has a usable
/// network path.
///
/// ``DefaultNetworkClient`` consults its injected ``ReachabilityProviding``
/// once per request, immediately before any transport activity. When
/// the provider returns `false` the client throws
/// ``NetworkError/offline`` without invoking the transport — saving
/// bandwidth, battery, and avoiding spurious errors that would
/// otherwise surface as ``NetworkError/transport(_:)``.
///
/// > Note: The check is a best-effort pre-flight. A brief connectivity
/// > loss between the gate and the actual transport hop can still
/// > produce a ``NetworkError/transport(_:)`` error; the gate is not a
/// > guarantee that the request will succeed if it gets past it.
///
/// When ``NetworkClientConfiguration/init(session:defaultHeaders:defaultTimeout:logger:validateHTTPStatus:reachability:)``
/// receives `nil` for `reachability`, an internal one-shot probe
/// backed by `HomerFoundation.Reachability.currentStatus()` is used.
/// To integrate with a long-lived observable connectivity store, inject
/// a ``HomerFoundation/Reachability`` instance directly — it conforms
/// to this protocol out of the box.
///
/// > Important: Implementations are called on the request's hot path
/// > and must be cheap (sub-100ms is the design target). A slow
/// > provider directly inflates request latency.
public protocol ReachabilityProviding: Sendable {
    /// Returns `true` when the device currently has a usable network
    /// path.
    func isReachable() async -> Bool
}
