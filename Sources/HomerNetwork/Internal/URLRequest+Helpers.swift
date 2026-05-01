import Foundation

/// Internal `URLRequest` ergonomics shared across the request-builder /
/// encoder layer. Kept `internal` so the public surface stays minimal —
/// these are tactical conveniences, not part of the contract.
extension URLRequest {

    /// Sets `value` for `field` only when no value is currently set, so
    /// caller-supplied headers always take precedence over library
    /// defaults.
    ///
    /// Used by ``JSONParameterEncoder``, ``URLParameterEncoder``, and
    /// ``RequestBuilder`` to install a default `Content-Type` without
    /// stomping on values the endpoint already declared. Centralising the
    /// guard removes three repeated `if value(forHTTPHeaderField:) == nil`
    /// blocks from the encoding layer.
    ///
    /// - Parameters:
    ///   - value: Header value to install when the field is currently
    ///     unset.
    ///   - field: Header field name. Comparison follows
    ///     `URLRequest.value(forHTTPHeaderField:)`'s case-insensitive rules.
    mutating func setHeaderIfAbsent(_ value: String, forField field: String) {
        guard self.value(forHTTPHeaderField: field) == nil else { return }
        setValue(value, forHTTPHeaderField: field)
    }
}
