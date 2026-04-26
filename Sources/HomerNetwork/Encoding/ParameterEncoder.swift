import Foundation

/// A strategy for serializing ``Parameters`` into a `URLRequest`.
///
/// Implementations are expected to be value types and `Sendable` so they
/// can be passed across actor boundaries.
public protocol ParameterEncoder: Sendable {
    func encode(_ parameters: Parameters, into request: inout URLRequest) throws
}
