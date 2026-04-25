import Testing
import Foundation
@_spi(HomerNetworkInternal) @testable import HomerNetwork

@Suite("RequestBuilder")
struct RequestBuilderTests {

    private let sut = RequestBuilder()
    private let defaultHeaders: HTTPHeaders = ["X-Client": "HomerNetwork"]
    private let defaultTimeout: TimeInterval = 30

    // MARK: - URL construction

    @Test("builds correct URL from baseURL + path")
    func buildsCorrectURL() throws {
        let endpoint = PlainEndpoint(path: "/users/42")
        let request = try sut.makeRequest(
            for: endpoint,
            defaultHeaders: defaultHeaders,
            defaultTimeout: defaultTimeout
        )
        #expect(request.url?.absoluteString == "https://api.example.com/users/42")
    }

    // MARK: - HTTP method

    @Test("sets HTTP method from endpoint", arguments: [
        (HTTPMethod.get,    "GET"),
        (HTTPMethod.post,   "POST"),
        (HTTPMethod.put,    "PUT"),
        (HTTPMethod.patch,  "PATCH"),
        (HTTPMethod.delete, "DELETE"),
    ])
    func setsHTTPMethod(method: HTTPMethod, expected: String) throws {
        let endpoint = PlainEndpoint(method: method)
        let request = try sut.makeRequest(
            for: endpoint,
            defaultHeaders: defaultHeaders,
            defaultTimeout: defaultTimeout
        )
        #expect(request.httpMethod == expected)
    }

    // MARK: - Header merging precedence

    @Test("default headers are applied to request")
    func defaultHeadersApplied() throws {
        let endpoint = PlainEndpoint()
        let request = try sut.makeRequest(
            for: endpoint,
            defaultHeaders: ["X-Default": "yes"],
            defaultTimeout: defaultTimeout
        )
        #expect(request.value(forHTTPHeaderField: "X-Default") == "yes")
    }

    @Test("endpoint allHeaders override default headers for same field")
    func endpointHeadersOverrideDefaults() throws {
        let endpoint = PlainEndpoint(extraHeaders: ["X-Client": "endpoint-value"])
        let request = try sut.makeRequest(
            for: endpoint,
            defaultHeaders: ["X-Client": "default-value"],
            defaultTimeout: defaultTimeout
        )
        #expect(request.value(forHTTPHeaderField: "X-Client") == "endpoint-value")
    }

    @Test("baseHeaders and endpoint headers both appear in merged result")
    func mergesBaseAndEndpointHeaders() throws {
        let endpoint = EndpointWithBaseHeaders(
            baseHeaders: ["X-Base": "base"],
            endpointHeaders: ["X-Endpoint": "endpoint"]
        )
        let request = try sut.makeRequest(
            for: endpoint,
            defaultHeaders: [:],
            defaultTimeout: defaultTimeout
        )
        #expect(request.value(forHTTPHeaderField: "X-Base") == "base")
        #expect(request.value(forHTTPHeaderField: "X-Endpoint") == "endpoint")
    }

    // MARK: - Timeout

    @Test("uses endpoint timeout when greater than zero")
    func usesEndpointTimeout() throws {
        let endpoint = PlainEndpoint(timeout: 60)
        let request = try sut.makeRequest(
            for: endpoint,
            defaultHeaders: defaultHeaders,
            defaultTimeout: 30
        )
        #expect(request.timeoutInterval == 60)
    }

    @Test("falls back to defaultTimeout when endpoint timeout is zero")
    func fallsBackToDefaultTimeout() throws {
        let endpoint = PlainEndpoint(timeout: 0)
        let request = try sut.makeRequest(
            for: endpoint,
            defaultHeaders: defaultHeaders,
            defaultTimeout: 45
        )
        #expect(request.timeoutInterval == 45)
    }

    // MARK: - .plain task

    @Test("plain task sets application/json Content-Type if absent")
    func plainTaskSetsContentType() throws {
        let endpoint = PlainEndpoint(task: .plain)
        let request = try sut.makeRequest(
            for: endpoint,
            defaultHeaders: [:],
            defaultTimeout: defaultTimeout
        )
        #expect(request.value(forHTTPHeaderField: "Content-Type") == HTTPHeader.Value.applicationJSON)
    }

    @Test("plain task does not overwrite existing Content-Type")
    func plainTaskDoesNotOverwriteContentType() throws {
        let endpoint = PlainEndpoint(
            task: .plain,
            extraHeaders: ["Content-Type": "text/plain"]
        )
        let request = try sut.makeRequest(
            for: endpoint,
            defaultHeaders: [:],
            defaultTimeout: defaultTimeout
        )
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "text/plain")
    }

    // MARK: - .parameters task

    @Test("parameters task with JSON encoding sets httpBody")
    func parametersJSONEncodingSetsBody() throws {
        let endpoint = PlainEndpoint(
            task: .parameters(body: ["user": "homer"], encoding: .json, query: nil)
        )
        let request = try sut.makeRequest(
            for: endpoint,
            defaultHeaders: [:],
            defaultTimeout: defaultTimeout
        )
        #expect(request.httpBody != nil)
    }

    @Test("parameters task with URL encoding appends query string")
    func parametersURLEncodingAppendsQuery() throws {
        let endpoint = PlainEndpoint(
            task: .parameters(body: nil, encoding: .url, query: ["page": 1])
        )
        let request = try sut.makeRequest(
            for: endpoint,
            defaultHeaders: [:],
            defaultTimeout: defaultTimeout
        )
        let components = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)
        #expect(components?.queryItems?.contains(URLQueryItem(name: "page", value: "1")) == true)
    }

    // MARK: - .parametersAndHeaders task

    @Test("parametersAndHeaders merges additional headers into request")
    func parametersAndHeadersMergesAdditional() throws {
        let endpoint = PlainEndpoint(
            task: .parametersAndHeaders(
                body: ["k": "v"],
                encoding: .json,
                query: nil,
                additionalHeaders: ["X-Request-ID": "abc123"]
            )
        )
        let request = try sut.makeRequest(
            for: endpoint,
            defaultHeaders: [:],
            defaultTimeout: defaultTimeout
        )
        #expect(request.value(forHTTPHeaderField: "X-Request-ID") == "abc123")
        #expect(request.httpBody != nil)
    }

    // MARK: - .multipart task

    @Test("multipart task sets Content-Type with boundary and encodes body")
    func multipartTaskSetsContentTypeAndBody() throws {
        let formData = MultipartFormData(
            parts: [.text(name: "field", value: "value")],
            boundary: "test-boundary"
        )
        let endpoint = PlainEndpoint(task: .multipart(formData, query: nil))
        let request = try sut.makeRequest(
            for: endpoint,
            defaultHeaders: [:],
            defaultTimeout: defaultTimeout
        )
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "multipart/form-data; boundary=test-boundary")
        #expect(request.httpBody != nil)
        #expect(request.httpBody?.isEmpty == false)
    }

    @Test("multipart task with query appends query items to URL")
    func multipartTaskWithQueryAppendsItems() throws {
        let formData = MultipartFormData(parts: [], boundary: "b")
        let endpoint = PlainEndpoint(
            task: .multipart(formData, query: ["ref": "upload"])
        )
        let request = try sut.makeRequest(
            for: endpoint,
            defaultHeaders: [:],
            defaultTimeout: defaultTimeout
        )
        let components = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)
        #expect(components?.queryItems?.contains(URLQueryItem(name: "ref", value: "upload")) == true)
    }
}

// MARK: - Test endpoint stubs

private struct PlainEndpoint: Endpoint {
    typealias Response = EmptyResponse

    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String
    var httpMethod: HTTPMethod
    var task: HTTPTask
    var timeout: TimeInterval
    var headers: HTTPHeaders

    init(
        path: String = "/items",
        method: HTTPMethod = .get,
        task: HTTPTask = .plain,
        timeout: TimeInterval = 0,
        extraHeaders: HTTPHeaders = [:]
    ) {
        self.path = path
        self.httpMethod = method
        self.task = task
        self.timeout = timeout
        self.headers = extraHeaders
    }
}

private struct EndpointWithBaseHeaders: Endpoint {
    typealias Response = EmptyResponse

    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String = "/items"
    var httpMethod: HTTPMethod = .get
    var task: HTTPTask = .plain
    var baseHeaders: HTTPHeaders
    var headers: HTTPHeaders

    init(baseHeaders: HTTPHeaders, endpointHeaders: HTTPHeaders) {
        self.baseHeaders = baseHeaders
        self.headers = endpointHeaders
    }
}

private struct EmptyResponse: Decodable, Sendable {}
