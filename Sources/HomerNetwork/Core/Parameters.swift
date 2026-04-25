import Foundation

/// A name-keyed bag of values used as query string or JSON body parameters.
///
/// Values must be `Sendable` so the dictionary can cross actor boundaries
/// safely. JSON-friendly primitives (`String`, `Int`, `Double`, `Bool`,
/// arrays/dictionaries of those, `NSNull`) are accepted by ``ParameterEncoding/json``.
public typealias Parameters = [String: any Sendable]
