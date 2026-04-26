import Foundation

/// A strategy for serializing ``HTTPParameters`` into a `URLRequest`.
///
/// Implementations are expected to be value types and `Sendable` so they
/// can be passed across actor boundaries.
public protocol ParameterEncoder: Sendable {
    /// Writes `parameters` into `request` (body, query, or both, per the
    /// implementation). Throws ``NetworkEncodingError`` on failure.
    func encode(_ parameters: HTTPParameters, into request: inout URLRequest) throws
}
