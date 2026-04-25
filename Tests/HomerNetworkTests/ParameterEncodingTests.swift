import Testing
import Foundation
@testable import HomerNetwork

@Suite("ParameterEncoding")
struct ParameterEncodingTests {

    private func makeRequest(url: String = "https://api.example.com/v1/users") -> URLRequest {
        URLRequest(url: URL(string: url)!)
    }

    // MARK: - URLParameterEncoder

    @Suite("URLParameterEncoder")
    struct URLParameterEncoderTests {

        @Test("appends single query item to URL")
        func appendsSingleQueryItem() throws {
            var request = URLRequest(url: URL(string: "https://api.example.com/search")!)
            let encoder = URLParameterEncoder()
            try encoder.encode(["q": "swift"], into: &request)
            let components = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)
            let items = try #require(components?.queryItems)
            #expect(items.contains(URLQueryItem(name: "q", value: "swift")))
        }

        @Test("appends multiple query items to URL")
        func appendsMultipleQueryItems() throws {
            var request = URLRequest(url: URL(string: "https://api.example.com/search")!)
            let encoder = URLParameterEncoder()
            try encoder.encode(["page": 1, "limit": 20], into: &request)
            let components = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)
            let items = try #require(components?.queryItems)
            #expect(items.count == 2)
        }

        @Test("preserves existing query items")
        func preservesExistingQueryItems() throws {
            var request = URLRequest(url: URL(string: "https://api.example.com/search?existing=yes")!)
            let encoder = URLParameterEncoder()
            try encoder.encode(["new": "value"], into: &request)
            let components = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)
            let items = try #require(components?.queryItems)
            #expect(items.count == 2)
        }

        @Test("sets form-urlencoded Content-Type when not already set")
        func setsContentTypeWhenAbsent() throws {
            var request = URLRequest(url: URL(string: "https://api.example.com")!)
            let encoder = URLParameterEncoder()
            try encoder.encode(["k": "v"], into: &request)
            #expect(request.value(forHTTPHeaderField: "Content-Type") == HTTPHeader.Value.applicationFormURLEncoded)
        }

        @Test("does not overwrite existing Content-Type")
        func doesNotOverwriteExistingContentType() throws {
            var request = URLRequest(url: URL(string: "https://api.example.com")!)
            request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
            let encoder = URLParameterEncoder()
            try encoder.encode(["k": "v"], into: &request)
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "text/plain")
        }

        @Test("throws missingURL when request has no URL")
        func throwsMissingURL() throws {
            var request = URLRequest(url: URL(string: "https://placeholder.com")!)
            request.url = nil
            let encoder = URLParameterEncoder()
            #expect(throws: NetworkEncodingError.missingURL) {
                try encoder.encode(["k": "v"], into: &request)
            }
        }

        @Test("replaces existing query item with same key instead of duplicating")
        func replacesExistingKey() throws {
            var request = URLRequest(url: URL(string: "https://api.example.com/items?page=1")!)
            let encoder = URLParameterEncoder()
            try encoder.encode(["page": "2"], into: &request)
            let components = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)
            let pageItems = (components?.queryItems ?? []).filter { $0.name == "page" }
            #expect(pageItems.count == 1)
            #expect(pageItems.first?.value == "2")
        }

        @Test("encodes Bool as 'true'/'false'")
        func encodesBoolAsString() throws {
            var request = URLRequest(url: URL(string: "https://api.example.com")!)
            let encoder = URLParameterEncoder()
            try encoder.encode(["active": true, "archived": false], into: &request)
            let items = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?.queryItems ?? []
            #expect(items.contains(URLQueryItem(name: "active", value: "true")))
            #expect(items.contains(URLQueryItem(name: "archived", value: "false")))
        }

        @Test("encodes Optional<some Sendable>.none as empty string instead of 'Optional(nil)'")
        func encodesNilAsEmpty() throws {
            var request = URLRequest(url: URL(string: "https://api.example.com")!)
            let encoder = URLParameterEncoder()
            let nilValue: Int? = nil
            try encoder.encode(["x": nilValue as any Sendable], into: &request)
            let items = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?.queryItems ?? []
            #expect(items.contains(URLQueryItem(name: "x", value: "")))
        }
    }

    // MARK: - JSONParameterEncoder

    @Suite("JSONParameterEncoder")
    struct JSONParameterEncoderTests {

        @Test("encodes parameters as JSON body")
        func encodesJSON() throws {
            var request = URLRequest(url: URL(string: "https://api.example.com")!)
            let encoder = JSONParameterEncoder()
            try encoder.encode(["name": "homer", "age": 42], into: &request)
            let body = try #require(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            #expect(json?["name"] as? String == "homer")
            #expect(json?["age"] as? Int == 42)
        }

        @Test("sets application/json Content-Type when absent")
        func setsContentTypeWhenAbsent() throws {
            var request = URLRequest(url: URL(string: "https://api.example.com")!)
            let encoder = JSONParameterEncoder()
            try encoder.encode(["k": "v"], into: &request)
            #expect(request.value(forHTTPHeaderField: "Content-Type") == HTTPHeader.Value.applicationJSON)
        }

        @Test("does not overwrite existing Content-Type")
        func doesNotOverwriteExistingContentType() throws {
            var request = URLRequest(url: URL(string: "https://api.example.com")!)
            request.setValue("application/vnd.api+json", forHTTPHeaderField: "Content-Type")
            let encoder = JSONParameterEncoder()
            try encoder.encode(["k": "v"], into: &request)
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/vnd.api+json")
        }

        @Test("throws jsonSerializationFailed with underlying message for un-serializable parameters")
        func throwsForInvalidJSON() {
            // Date is Sendable so it satisfies Parameters' value type but is
            // not JSON-serializable via JSONSerialization.
            var request = URLRequest(url: URL(string: "https://api.example.com")!)
            let encoder = JSONParameterEncoder()
            do {
                try encoder.encode(["created": Date()], into: &request)
                Issue.record("expected jsonSerializationFailed to be thrown")
            } catch let NetworkEncodingError.jsonSerializationFailed(underlying) {
                #expect(!underlying.isEmpty)
            } catch {
                Issue.record("unexpected error: \(error)")
            }
        }
    }

    // MARK: - ParameterEncoding enum apply matrix

    @Suite("ParameterEncoding.apply")
    struct ParameterEncodingApplyTests {

        private func makeRequest() -> URLRequest {
            URLRequest(url: URL(string: "https://api.example.com/items")!)
        }

        @Test("url encoding appends query params from body when query is nil")
        func urlEncodingUsesBodyAsQuery() throws {
            var request = makeRequest()
            try ParameterEncoding.url.apply(to: &request, body: ["search": "term"], query: nil)
            let components = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)
            #expect(components?.queryItems?.contains(URLQueryItem(name: "search", value: "term")) == true)
        }

        @Test("url encoding prefers query over body when both provided")
        func urlEncodingPrefersQueryOverBody() throws {
            var request = makeRequest()
            try ParameterEncoding.url.apply(to: &request, body: ["body": "ignored"], query: ["q": "active"])
            let components = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)
            let items = components?.queryItems ?? []
            #expect(items.contains(URLQueryItem(name: "q", value: "active")))
            #expect(!items.contains(URLQueryItem(name: "body", value: "ignored")))
        }

        @Test("json encoding sets httpBody")
        func jsonEncodingSetsBody() throws {
            var request = makeRequest()
            try ParameterEncoding.json.apply(to: &request, body: ["key": "value"], query: nil)
            #expect(request.httpBody != nil)
            #expect(request.httpBody?.isEmpty == false)
        }

        @Test("json encoding ignores nil body")
        func jsonEncodingIgnoresNilBody() throws {
            var request = makeRequest()
            try ParameterEncoding.json.apply(to: &request, body: nil, query: nil)
            #expect(request.httpBody == nil)
        }

        @Test("urlAndJSON encodes query as URL and body as JSON")
        func urlAndJSONEncodesBoth() throws {
            var request = makeRequest()
            try ParameterEncoding.urlAndJSON.apply(
                to: &request,
                body: ["name": "homer"],
                query: ["page": 1]
            )
            let components = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)
            #expect(components?.queryItems?.contains(URLQueryItem(name: "page", value: "1")) == true)
            let body = try #require(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            #expect(json?["name"] as? String == "homer")
        }

        @Test("rawBody sets httpBody verbatim")
        func rawBodySetsBodyVerbatim() throws {
            let rawData = Data("raw-bytes".utf8)
            var request = makeRequest()
            try ParameterEncoding.rawBody(rawData).apply(to: &request, body: nil, query: nil)
            #expect(request.httpBody == rawData)
        }

        @Test("custom encoding delegates to provided encoder")
        func customEncodingDelegates() throws {
            let recorder = RecordingEncoder()
            var request = makeRequest()
            try ParameterEncoding.custom(recorder).apply(to: &request, body: ["x": "y"], query: nil)
            #expect(recorder.lastParameters?["x"] as? String == "y")
        }
    }
}

// MARK: - Test helpers

private final class RecordingEncoder: ParameterEncoder, @unchecked Sendable {
    var lastParameters: Parameters?

    func encode(_ parameters: Parameters, into request: inout URLRequest) throws {
        lastParameters = parameters
    }
}
