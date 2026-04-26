import Foundation

/// A name-keyed bag of values used as query string or JSON body parameters.
///
/// Values must be `Sendable` so the dictionary can cross actor boundaries
/// safely.
///
/// > Important: Even though the value type is `any Sendable`, only the
/// > set of values that `JSONSerialization` accepts will encode correctly:
/// > `String`, `NSNumber`-bridged numerics (`Int`, `Double`, `Bool`),
/// > `NSNull`, and arrays / dictionaries of those. Passing `Date`, `Data`,
/// > `URL`, `UUID`, or custom structs is a *runtime* error from
/// > ``JSONParameterEncoder``; ``URLParameterEncoder`` falls back to
/// > `String(describing:)`, which produces locale-dependent output that is
/// > rarely what a backend expects. Convert such values at the call site
/// > (e.g. ISO 8601 strings for dates) before placing them in `Parameters`.
public typealias Parameters = [String: any Sendable]
