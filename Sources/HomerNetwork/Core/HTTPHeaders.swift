import Foundation

/// A case-insensitive collection of HTTP header field/value pairs.
///
/// `HTTPHeaders` preserves insertion order while comparing field names
/// case-insensitively, matching the behavior of `URLRequest.allHTTPHeaderFields`.
public struct HTTPHeaders: Sendable, Hashable, ExpressibleByDictionaryLiteral, Sequence {
    public typealias Key = String
    public typealias Value = String

    /// A single field/value pair.
    public struct Entry: Sendable, Hashable {
        public let field: String
        public let value: String

        public init(field: String, value: String) {
            self.field = field
            self.value = value
        }
    }

    private var storage: [Entry] = []

    public init() {}

    public init(_ dictionary: [String: String]) {
        for (key, value) in dictionary {
            set(value, forField: key)
        }
    }

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
    public var dictionary: [String: String] {
        Dictionary(uniqueKeysWithValues: storage.map { ($0.field, $0.value) })
    }

    public var isEmpty: Bool { storage.isEmpty }
    public var count: Int { storage.count }

    public func makeIterator() -> IndexingIterator<[Entry]> {
        storage.makeIterator()
    }
}

/// Common header field names and values used by ``NetworkClient``.
public enum HTTPHeader {
    public enum Field {
        public static let contentType = "Content-Type"
        public static let accept = "Accept"
        public static let authorization = "Authorization"
        public static let userAgent = "User-Agent"
    }

    public enum Value {
        public static let applicationJSON = "application/json"
        public static let applicationFormURLEncoded = "application/x-www-form-urlencoded; charset=utf-8"
    }
}
