import Foundation

/// A pluggable observer for outgoing requests and incoming responses.
///
/// Conformers see every request / response pair processed by
/// ``NetworkManager``; implementations should be inexpensive and
/// side-effect-free (typically writing to `os.Logger` or a file). All
/// three methods are required so silent overrides are explicit — use
/// ``NoopNetworkLogger`` when no logging is desired, or build on top
/// of ``FoundationNetworkLogger`` to route into the
/// `HomerFoundation.Log` channel.
///
/// > Warning: ``log(response:data:)`` receives the unfiltered response
/// > body. For many APIs this contains PII or credentials — do not
/// > forward `data` to telemetry, crash reports, or remote sinks
/// > without redacting first. ``FoundationNetworkLogger`` does **not**
/// > emit response bodies; it only logs the status code and byte count.
public protocol NetworkLogger: Sendable {
    /// Called immediately before the transport sends `request`.
    func log(request: URLRequest)
    /// Called when a response (any status) and its body bytes have been
    /// received from the transport. The body is delivered raw — see the
    /// PII warning on the protocol-level documentation.
    func log(response: HTTPURLResponse, data: Data)
    /// Called for any error produced by the encoding, transport, or
    /// decoding stage of ``NetworkManager``.
    func log(error: any Error)
}
