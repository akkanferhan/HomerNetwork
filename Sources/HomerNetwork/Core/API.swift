import Foundation

/// The shared properties of every endpoint group (a service, a feature, a
/// vendor SDK).
///
/// Conformers usually wrap an enum that lists each endpoint, with `baseURL`
/// and `baseHeaders` returning constants and the per-case overrides
/// implemented in the ``Endpoint`` extension.
public protocol API: Sendable {
    /// The scheme + host (and optional path prefix) for every endpoint in
    /// this group.
    var baseURL: URL { get }
    /// Headers applied to every request — typically API keys or User-Agent.
    var baseHeaders: HTTPHeaders { get }
    /// The default request timeout in seconds.
    var timeout: TimeInterval { get }
}

public extension API {
    var baseHeaders: HTTPHeaders { [:] }
    var timeout: TimeInterval { HomerNetworkDefaults.timeoutInterval }
}
