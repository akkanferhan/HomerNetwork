import Foundation

/// A case-insensitive collection of HTTP header field/value pairs.
///
/// `HTTPHeaders` preserves insertion order while comparing field names
/// case-insensitively, matching the behavior of `URLRequest.allHTTPHeaderFields`.
public struct HTTPHeaders: Sendable, Hashable, ExpressibleByDictionaryLiteral, Sequence {
    /// Dictionary literal key type — the header field name.
    public typealias Key = String
    /// Dictionary literal value type — the header value.
    public typealias Value = String

    /// A single field/value pair preserving the field name's original casing.
    public struct Entry: Sendable, Hashable {
        /// The header field name as supplied by the caller (case preserved).
        public let field: String
        /// The header value associated with ``field``.
        public let value: String

        /// Creates an entry from a field name and its associated value.
        public init(field: String, value: String) {
            self.field = field
            self.value = value
        }
    }

    private var storage: [Entry] = []

    /// Creates an empty header collection.
    public init() {}

    /// Creates a collection from a `[String: String]` dictionary; iteration
    /// order matches the dictionary's order.
    public init(_ dictionary: [String: String]) {
        for (key, value) in dictionary {
            set(value, forField: key)
        }
    }

    /// Dictionary-literal initializer, e.g. `["Accept": "application/json"]`.
    public init(dictionaryLiteral elements: (String, String)...) {
        for (key, value) in elements {
            set(value, forField: key)
        }
    }

    /// Returns the value for the given field, or `nil` if absent.
    public func value(forField field: String) -> String? {
        storage.first { $0.field.caseInsensitiveCompare(field) == .orderedSame }?.value
    }

    /// Sets the value for the given field, replacing any existing entry.
    public mutating func set(_ value: String, forField field: String) {
        if let index = storage.firstIndex(where: { $0.field.caseInsensitiveCompare(field) == .orderedSame }) {
            storage[index] = Entry(field: field, value: value)
        } else {
            storage.append(Entry(field: field, value: value))
        }
    }

    /// Removes the entry for the given field, if present.
    public mutating func remove(field: String) {
        storage.removeAll { $0.field.caseInsensitiveCompare(field) == .orderedSame }
    }

    /// Merges `other` into this collection. Conflicting fields are overwritten.
    public mutating func merge(_ other: HTTPHeaders) {
        for entry in other.storage {
            set(entry.value, forField: entry.field)
        }
    }

    /// A new collection produced by merging `other` on top of this one.
    public func merging(_ other: HTTPHeaders) -> HTTPHeaders {
        var copy = self
        copy.merge(other)
        return copy
    }

    /// Snapshot as a `[String: String]` dictionary suitable for `URLRequest.allHTTPHeaderFields`.
    ///
    /// `set(_:forField:)` already collapses duplicates case-insensitively,
    /// so under normal use this dictionary holds one entry per header.
    /// `uniquingKeysWith:` is defensive: if any future code path stashes
    /// two entries with the same field, the later one wins instead of the
    /// runtime trapping.
    public var dictionary: [String: String] {
        Dictionary(storage.map { ($0.field, $0.value) }, uniquingKeysWith: { _, last in last })
    }

    /// `true` when no entries are stored.
    public var isEmpty: Bool { storage.isEmpty }
    /// The number of stored entries.
    public var count: Int { storage.count }

    /// Iterates entries in insertion order.
    public func makeIterator() -> IndexingIterator<[Entry]> {
        storage.makeIterator()
    }
}

/// Common header field names and values used by ``NetworkClient``.
public enum HTTPHeader {
    /// Canonical HTTP header field names.
    public enum Field {
        /// `Content-Type` — describes the media type of the request body.
        public static let contentType = "Content-Type"
        /// `Accept` — advertises which media types the client can parse.
        public static let accept = "Accept"
    }

    /// Canonical HTTP header values paired with ``HTTPHeader/Field``.
    public enum Value {
        /// `application/json` — JSON request or response body.
        public static let applicationJSON = "application/json"
        /// `application/x-www-form-urlencoded; charset=utf-8` — URL-form body.
        public static let applicationFormURLEncoded = "application/x-www-form-urlencoded; charset=utf-8"
    }
}
