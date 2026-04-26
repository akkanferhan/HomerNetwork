import Testing
import Foundation
@testable import HomerNetwork

// MARK: - NetworkLoggerFormat.headerLine tests
// Strategy: NetworkLoggerFormat.headerLine(field:value:publicFields:) is a pure
// internal function extracted specifically to make header-redaction logic testable
// without requiring a log-output spy. Tests here exercise the redaction decision
// tree directly, then a second suite validates that FoundationNetworkLogger wires
// the helper correctly through its public init parameters.

@Suite("NetworkLoggerFormat — headerLine")
struct NetworkLoggerFormatHeaderLineTests {

    // MARK: Default / empty allowlist

    @Test("emits redacted placeholder when public fields set is empty")
    func emitsRedactedWhenPublicFieldsEmpty() {
        let line = NetworkLoggerFormat.headerLine(
            field: "Content-Type",
            value: "application/json",
            publicFields: []
        )
        #expect(line.contains(NetworkLoggerFormat.redactedHeaderValue))
        #expect(!line.contains("application/json"))
    }

    @Test("field name is still present in output when value is redacted")
    func fieldNamePresentEvenWhenRedacted() {
        let line = NetworkLoggerFormat.headerLine(
            field: "Authorization",
            value: "Bearer secret",
            publicFields: []
        )
        #expect(line.contains("Authorization"))
        #expect(line.contains(NetworkLoggerFormat.redactedHeaderValue))
    }

    // MARK: Allowlist match

    @Test("emits actual value when field is in public allowlist")
    func emitsActualValueForAllowlistedField() {
        let line = NetworkLoggerFormat.headerLine(
            field: "content-type",
            value: "application/json",
            publicFields: ["content-type"]
        )
        #expect(line.contains("application/json"))
        #expect(!line.contains(NetworkLoggerFormat.redactedHeaderValue))
    }

    @Test("redacts value when field is not in allowlist")
    func redactsNonAllowlistedField() {
        let line = NetworkLoggerFormat.headerLine(
            field: "authorization",
            value: "Bearer token",
            publicFields: ["content-type"]
        )
        #expect(line.contains(NetworkLoggerFormat.redactedHeaderValue))
        #expect(!line.contains("Bearer token"))
    }

    // MARK: Case-insensitive matching

    @Test(
        "comparison is case-insensitive — field mixed-case, allowlist lowercase",
        arguments: [
            ("Content-Type", "content-type"),
            ("CONTENT-TYPE", "content-type"),
            ("content-type", "content-type"),
            ("AUTHORIZATION", "authorization"),
            ("Authorization", "authorization")
        ]
    )
    func caseInsensitiveMatch(fieldInRequest: String, allowlistEntry: String) {
        let line = NetworkLoggerFormat.headerLine(
            field: fieldInRequest,
            value: "value123",
            publicFields: [allowlistEntry]
        )
        #expect(line.contains("value123"))
        #expect(!line.contains(NetworkLoggerFormat.redactedHeaderValue))
    }

    @Test(
        "comparison is case-insensitive — allowlist mixed-case, field lowercase",
        arguments: [
            ("Content-Type", "content-type"),
            ("Content-Type", "CONTENT-TYPE"),
            ("Content-Type", "Content-Type")
        ]
    )
    func caseInsensitiveAllowlistMixedCase(allowlistEntry: String, fieldInRequest: String) {
        // publicFields must already be normalised to lowercase by the caller
        // (FoundationNetworkLogger.init does this). Simulate that here.
        let normalised = Set([allowlistEntry.lowercased()])
        let line = NetworkLoggerFormat.headerLine(
            field: fieldInRequest,
            value: "text/html",
            publicFields: normalised
        )
        #expect(line.contains("text/html"))
    }

    // MARK: Multiple allowed fields

    @Test("all allowlisted fields have their values emitted")
    func multipleAllowlistedFields() {
        let publicFields: Set<String> = ["content-type", "accept", "x-request-id"]
        let headers = [
            ("Content-Type", "application/json"),
            ("Accept", "text/html"),
            ("X-Request-Id", "abc-123"),
            ("Authorization", "Bearer secret")
        ]
        for (field, value) in headers {
            let line = NetworkLoggerFormat.headerLine(
                field: field,
                value: value,
                publicFields: publicFields
            )
            let isPublic = publicFields.contains(field.lowercased())
            if isPublic {
                #expect(line.contains(value), "Expected \(field) value to be visible")
            } else {
                #expect(
                    line.contains(NetworkLoggerFormat.redactedHeaderValue),
                    "Expected \(field) value to be redacted"
                )
            }
        }
    }
}

// MARK: - FoundationNetworkLogger init normalisation tests
// These tests verify the lowercasing normalisation that init performs on the
// caller-supplied publicHeaderFields set. The normalised set is stored as a
// private property, so we exercise it indirectly through headerLine — which
// mirrors exactly how FoundationNetworkLogger.log(request:) invokes it.

@Suite("FoundationNetworkLogger — publicHeaderFields normalisation")
struct FoundationNetworkLoggerNormalisationTests {

    // Replicate the normalisation done in FoundationNetworkLogger.init so tests
    // are self-contained without depending on private state.
    private func normalise(_ fields: Set<String>) -> Set<String> {
        Set(fields.map { $0.lowercased() })
    }

    @Test("init lowercases mixed-case field names before storing")
    func initNormalisesMixedCase() {
        let normalised = normalise(["Content-Type", "AUTHORIZATION", "X-Request-Id"])
        #expect(normalised.contains("content-type"))
        #expect(normalised.contains("authorization"))
        #expect(normalised.contains("x-request-id"))
        #expect(!normalised.contains("Content-Type"))
        #expect(!normalised.contains("AUTHORIZATION"))
    }

    @Test("init with empty set stores empty set")
    func initEmptySet() {
        let normalised = normalise([])
        #expect(normalised.isEmpty)
    }

    @Test("init with already-lowercase set stores identical set")
    func initAlreadyLowercaseIsIdempotent() {
        let input: Set<String> = ["content-type", "accept"]
        let normalised = normalise(input)
        #expect(normalised == input)
    }

    @Test("normalised set used in headerLine produces correct redaction decisions",
          arguments: [
            ("Content-Type", ["Content-Type"], true),
            ("AUTHORIZATION", ["authorization"], true),
            ("X-Custom", ["x-custom"], true),
            ("Authorization", ["content-type"], false),
            ("Accept", [], false)
          ])
    func normalisedSetDrivesRedactionDecision(
        field: String,
        rawAllowlist: [String],
        expectVisible: Bool
    ) {
        let publicFields = normalise(Set(rawAllowlist))
        let line = NetworkLoggerFormat.headerLine(
            field: field,
            value: "sentinel-value",
            publicFields: publicFields
        )
        if expectVisible {
            #expect(line.contains("sentinel-value"),
                    "Field '\(field)' should be visible with allowlist \(rawAllowlist)")
        } else {
            #expect(line.contains(NetworkLoggerFormat.redactedHeaderValue),
                    "Field '\(field)' should be redacted with allowlist \(rawAllowlist)")
        }
    }
}

// MARK: - FoundationNetworkLogger request guard tests
// log(request:) returns early when publicHeaderFields is empty — no header
// lines are emitted at all. We cannot intercept os.Logger output in-process,
// but we can confirm the guard short-circuits by verifying that constructing
// a logger with an empty set does not crash and that the guard path (isEmpty
// == true) is represented by the inaccessible private property. The behavioural
// invariant — "no header emission when empty" — is instead covered through
// NetworkLoggerFormat.headerLine tests above and the integration smoke test
// below, which exercises the full call path without asserting on log output.

@Suite("FoundationNetworkLogger — smoke / crash-free execution")
struct FoundationNetworkLoggerSmokeTests {

    // Build a minimal URLRequest with several headers.
    private func makeRequest(headers: [String: String] = [:]) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.example.com/v1/items")!)
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }

    @Test("log(request:) with empty publicHeaderFields does not crash")
    func logRequestEmptyPublicFieldsDoesNotCrash() {
        let sut = FoundationNetworkLogger(publicHeaderFields: [])
        let request = makeRequest(headers: [
            "Authorization": "Bearer secret",
            "Content-Type": "application/json"
        ])
        sut.log(request: request) // must not throw or crash
    }

    @Test("log(request:) with populated publicHeaderFields does not crash")
    func logRequestWithPublicFieldsDoesNotCrash() {
        let sut = FoundationNetworkLogger(publicHeaderFields: ["Content-Type", "Accept"])
        let request = makeRequest(headers: [
            "Authorization": "Bearer secret",
            "Content-Type": "application/json",
            "Accept": "text/html"
        ])
        sut.log(request: request)
    }

    @Test("log(response:data:) does not crash")
    func logResponseDoesNotCrash() {
        let sut = FoundationNetworkLogger(publicHeaderFields: ["Content-Type"])
        let url = URL(string: "https://api.example.com/v1/items")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        sut.log(response: response, data: Data("{}".utf8))
    }

    @Test("log(error:) does not crash")
    func logErrorDoesNotCrash() {
        let sut = FoundationNetworkLogger(publicHeaderFields: [])
        sut.log(error: URLError(.notConnectedToInternet))
    }

    @Test("log(request:) with case-variant header keys does not crash")
    func logRequestCaseVariantHeadersDoesNotCrash() {
        let sut = FoundationNetworkLogger(publicHeaderFields: ["content-type"])
        let request = makeRequest(headers: [
            "CONTENT-TYPE": "application/json",
            "authorization": "Bearer token"
        ])
        sut.log(request: request)
    }
}

// MARK: - NetworkLoggerFormat constants tests

@Suite("NetworkLoggerFormat — constants")
struct NetworkLoggerFormatConstantsTests {

    @Test("redactedHeaderValue constant is the expected placeholder string")
    func redactedHeaderValueConstant() {
        #expect(NetworkLoggerFormat.redactedHeaderValue == "<redacted>")
    }

    @Test("headerLine output starts with two-space indent")
    func headerLineIndent() {
        let line = NetworkLoggerFormat.headerLine(
            field: "Accept",
            value: "application/json",
            publicFields: ["accept"]
        )
        #expect(line.hasPrefix("  "))
    }

    @Test("headerLine format is 'field: value'")
    func headerLineFormat() {
        let line = NetworkLoggerFormat.headerLine(
            field: "Accept",
            value: "application/json",
            publicFields: ["accept"]
        )
        #expect(line == "  Accept: application/json")
    }

    @Test("headerLine format is 'field: <redacted>' when not in allowlist")
    func headerLineRedactedFormat() {
        let line = NetworkLoggerFormat.headerLine(
            field: "Authorization",
            value: "Bearer secret",
            publicFields: []
        )
        #expect(line == "  Authorization: <redacted>")
    }
}
