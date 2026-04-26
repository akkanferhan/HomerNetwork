import Testing
@testable import HomerNetwork

@Suite("HTTPHeaders")
struct HTTPHeadersTests {

    // MARK: - init

    @Test("empty init produces empty headers")
    func emptyInit() {
        let sut = HTTPHeaders()
        #expect(sut.isEmpty)
        #expect(sut.count == 0)
    }

    @Test("dictionary init stores all key-value pairs")
    func dictionaryInit() {
        let sut = HTTPHeaders(["Content-Type": "application/json", "Accept": "text/html"])
        #expect(sut.count == 2)
        #expect(sut.value(forField: "Content-Type") == "application/json")
        #expect(sut.value(forField: "Accept") == "text/html")
    }

    @Test("dictionary literal init stores all key-value pairs")
    func dictionaryLiteralInit() {
        let sut: HTTPHeaders = ["Authorization": "Bearer token", "Accept": "application/json"]
        #expect(sut.count == 2)
        #expect(sut.value(forField: "Authorization") == "Bearer token")
    }

    // MARK: - value(forField:)

    @Test("value(forField:) returns nil for missing key")
    func valueForMissingField() {
        let sut = HTTPHeaders()
        #expect(sut.value(forField: "X-Missing") == nil)
    }

    @Test("value(forField:) is case-insensitive", arguments: [
        "content-type", "Content-Type", "CONTENT-TYPE", "cOnTeNt-TyPe"
    ])
    func valueIsCaseInsensitive(field: String) {
        var sut = HTTPHeaders()
        sut.set("application/json", forField: "Content-Type")
        #expect(sut.value(forField: field) == "application/json")
    }

    // MARK: - set(_:forField:)

    @Test("set replaces existing value for same field (case-insensitive)")
    func setReplacesExisting() {
        var sut = HTTPHeaders()
        sut.set("text/plain", forField: "Content-Type")
        sut.set("application/json", forField: "content-type")
        #expect(sut.count == 1)
        #expect(sut.value(forField: "Content-Type") == "application/json")
    }

    @Test("set appends new field when key is absent")
    func setAppendsNew() {
        var sut = HTTPHeaders()
        sut.set("Bearer abc", forField: "Authorization")
        sut.set("application/json", forField: "Accept")
        #expect(sut.count == 2)
    }

    // MARK: - remove(field:)

    @Test("remove deletes existing field case-insensitively")
    func removeDeletesField() {
        var sut: HTTPHeaders = ["Content-Type": "application/json", "Accept": "text/html"]
        sut.remove(field: "content-type")
        #expect(sut.count == 1)
        #expect(sut.value(forField: "Content-Type") == nil)
        #expect(sut.value(forField: "Accept") == "text/html")
    }

    @Test("remove on absent field is a no-op")
    func removeAbsentFieldIsNoop() {
        var sut: HTTPHeaders = ["Accept": "application/json"]
        sut.remove(field: "X-Non-Existent")
        #expect(sut.count == 1)
    }

    // MARK: - merge / merging

    @Test("merge overwrites conflicting fields with other's values")
    func mergeOverwritesConflicts() {
        var base: HTTPHeaders = ["Accept": "text/html", "Authorization": "Bearer old"]
        let override: HTTPHeaders = ["Accept": "application/json", "X-Custom": "value"]
        base.merge(override)
        #expect(base.count == 3)
        #expect(base.value(forField: "Accept") == "application/json")
        #expect(base.value(forField: "Authorization") == "Bearer old")
        #expect(base.value(forField: "X-Custom") == "value")
    }

    @Test("merging returns new instance leaving original unchanged")
    func mergingLeavesOriginalUnchanged() {
        let base: HTTPHeaders = ["Accept": "text/html"]
        let override: HTTPHeaders = ["Accept": "application/json"]
        let merged = base.merging(override)
        #expect(base.value(forField: "Accept") == "text/html")
        #expect(merged.value(forField: "Accept") == "application/json")
    }

    @Test("merging empty other returns equal copy")
    func mergingEmptyOther() {
        let base: HTTPHeaders = ["Content-Type": "application/json"]
        let merged = base.merging(HTTPHeaders())
        #expect(merged.count == base.count)
        #expect(merged.value(forField: "Content-Type") == "application/json")
    }

    // MARK: - dictionary

    @Test("dictionary produces correct String:String snapshot")
    func dictionarySnapshot() {
        let sut: HTTPHeaders = ["Content-Type": "application/json", "Accept": "text/html"]
        let dict = sut.dictionary
        #expect(dict["Content-Type"] == "application/json")
        #expect(dict["Accept"] == "text/html")
        #expect(dict.count == 2)
    }

    @Test("dictionary on empty headers is empty")
    func emptyDictionary() {
        let sut = HTTPHeaders()
        #expect(sut.dictionary.isEmpty)
    }

    // MARK: - Sequence

    @Test("makeIterator yields all stored entries")
    func sequenceIteration() {
        let sut: HTTPHeaders = ["Content-Type": "application/json", "Accept": "text/html"]
        var fields: [String] = []
        for entry in sut {
            fields.append(entry.field)
        }
        #expect(fields.count == 2)
        #expect(fields.contains("Content-Type"))
        #expect(fields.contains("Accept"))
    }

    // MARK: - Hashable / Equatable

    @Test("two headers with same fields are equal")
    func equality() {
        let a: HTTPHeaders = ["Content-Type": "application/json"]
        let b: HTTPHeaders = ["Content-Type": "application/json"]
        #expect(a == b)
    }

    @Test("headers with different values are not equal")
    func inequality() {
        let a: HTTPHeaders = ["Content-Type": "application/json"]
        let b: HTTPHeaders = ["Content-Type": "text/plain"]
        #expect(a != b)
    }

    @Test("equal headers produce same hash value")
    func hashConsistency() {
        let a: HTTPHeaders = ["Accept": "application/json"]
        let b: HTTPHeaders = ["Accept": "application/json"]
        #expect(a.hashValue == b.hashValue)
    }

    // MARK: - HTTPHeader field/value constants

    @Test("HTTPHeader.Field constants have correct raw strings")
    func fieldConstants() {
        #expect(HTTPHeader.Field.contentType == "Content-Type")
        #expect(HTTPHeader.Field.accept == "Accept")
    }

    @Test("HTTPHeader.Value constants have correct raw strings")
    func valueConstants() {
        #expect(HTTPHeader.Value.applicationJSON == "application/json")
        #expect(HTTPHeader.Value.applicationFormURLEncoded.contains("application/x-www-form-urlencoded"))
    }
}
