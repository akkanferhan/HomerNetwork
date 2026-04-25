import Testing
import Foundation
@testable import HomerNetwork

// Convenience alias to disambiguate DefaultNetworkClient.send
private typealias Client = any NetworkClient

@Suite("DefaultNetworkClient")
struct DefaultNetworkClientTests {

    // MARK: - 2xx + successful decode

    @Test("returns decoded value and correct status for 2xx response")
    func returnsDecodedValueFor2xx() async throws {
        let payload = UserPayload(id: "42", name: "Homer")
        let data = try JSONEncoder().encode(payload)
        let session = MockURLSession(result: .success((data, makeHTTPResponse(statusCode: 200))))
        let client: Client = DefaultNetworkClient(configuration: makeConfig(session: session))

        let response = try await client.send(UserEndpoint())

        #expect(response.value.id == "42")
        #expect(response.value.name == "Homer")
        #expect(response.status.statusCode == 200)
        #expect(response.status.isSuccess)
    }

    @Test("NetworkResponse carries raw data and headers")
    func responseCarriesDataAndHeaders() async throws {
        let payload = UserPayload(id: "1", name: "Bart")
        let data = try JSONEncoder().encode(payload)
        let httpResponse = makeHTTPResponse(statusCode: 200, headers: ["X-Request-ID": "req-001"])
        let session = MockURLSession(result: .success((data, httpResponse)))
        let client: Client = DefaultNetworkClient(configuration: makeConfig(session: session))

        let response = try await client.send(UserEndpoint())

        #expect(response.data == data)
        #expect(response.headers.value(forField: "X-Request-ID") == "req-001")
    }

    // MARK: - 4xx → NetworkError.http

    @Test("throws NetworkError.http for 4xx response when validateHTTPStatus is true", arguments: [400, 401, 403, 404, 422])
    func throwsHTTPErrorFor4xx(statusCode: Int) async throws {
        let errorData = Data("{\"error\":\"not found\"}".utf8)
        let session = MockURLSession(result: .success((errorData, makeHTTPResponse(statusCode: statusCode))))
        let client: Client = DefaultNetworkClient(configuration: makeConfig(session: session, validateHTTPStatus: true))

        var caughtHTTP = false
        do {
            _ = try await client.send(UserEndpoint())
        } catch let error as NetworkError {
            if case .http(let status, let body) = error {
                caughtHTTP = true
                #expect(status.statusCode == statusCode)
                #expect(body == errorData)
            }
        }
        #expect(caughtHTTP, "Expected NetworkError.http to be thrown for status \(statusCode)")
    }

    // MARK: - 2xx + broken JSON → NetworkError.decoding

    @Test("throws NetworkError.decoding for 2xx with malformed JSON")
    func throwsDecodingErrorForMalformedJSON() async throws {
        let malformed = Data("not-valid-json".utf8)
        let session = MockURLSession(result: .success((malformed, makeHTTPResponse(statusCode: 200))))
        let client: Client = DefaultNetworkClient(configuration: makeConfig(session: session))

        var caughtDecoding = false
        do {
            _ = try await client.send(UserEndpoint())
        } catch let error as NetworkError {
            if case .decoding(_, let data) = error {
                caughtDecoding = true
                #expect(data == malformed)
            }
        }
        #expect(caughtDecoding, "Expected NetworkError.decoding to be thrown")
    }

    // MARK: - validateHTTPStatus = false

    @Test("decodes body even for 4xx when validateHTTPStatus is false")
    func decodesBodyFor4xxWhenValidationDisabled() async throws {
        let payload = UserPayload(id: "99", name: "Error User")
        let data = try JSONEncoder().encode(payload)
        let session = MockURLSession(result: .success((data, makeHTTPResponse(statusCode: 400))))
        let client: Client = DefaultNetworkClient(
            configuration: makeConfig(session: session, validateHTTPStatus: false)
        )

        let response = try await client.send(UserEndpoint())
        #expect(response.value.id == "99")
        #expect(response.status.statusCode == 400)
        #expect(!response.status.isSuccess)
    }

    // MARK: - URLSession transport error

    @Test("throws NetworkError.transport when URLSession throws")
    func throwsTransportOnSessionError() async throws {
        let session = MockURLSession(result: .failure(URLError(.notConnectedToInternet)))
        let client: Client = DefaultNetworkClient(configuration: makeConfig(session: session))

        var caughtTransport = false
        do {
            _ = try await client.send(UserEndpoint())
        } catch let error as NetworkError {
            if case .transport = error {
                caughtTransport = true
            }
        }
        #expect(caughtTransport, "Expected NetworkError.transport to be thrown")
    }

    // MARK: - Non-HTTPURLResponse → invalidResponse

    @Test("throws NetworkError.invalidResponse when response is not HTTPURLResponse")
    func throwsInvalidResponseForNonHTTP() async throws {
        let plainResponse = URLResponse(
            url: URL(string: "https://api.example.com")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        let session = MockURLSession(result: .success((Data(), plainResponse)))
        let client: Client = DefaultNetworkClient(configuration: makeConfig(session: session))

        var caughtInvalidResponse = false
        do {
            _ = try await client.send(UserEndpoint())
        } catch let error as NetworkError {
            if case .invalidResponse = error {
                caughtInvalidResponse = true
            }
        }
        #expect(caughtInvalidResponse, "Expected NetworkError.invalidResponse to be thrown")
    }

    // MARK: - Logger is called

    @Test("logger receives request log call on successful send")
    func loggerReceivesRequestCall() async throws {
        let payload = UserPayload(id: "1", name: "Marge")
        let data = try JSONEncoder().encode(payload)
        let session = MockURLSession(result: .success((data, makeHTTPResponse(statusCode: 200))))
        let logger = RecordingLogger()
        let client: Client = DefaultNetworkClient(
            configuration: makeConfig(session: session, logger: logger)
        )

        _ = try await client.send(UserEndpoint())

        #expect(logger.requestLogCount > 0)
    }

    @Test("logger receives error log call on transport failure")
    func loggerReceivesErrorOnTransportFailure() async throws {
        let session = MockURLSession(result: .failure(URLError(.timedOut)))
        let logger = RecordingLogger()
        let client: Client = DefaultNetworkClient(
            configuration: makeConfig(session: session, logger: logger)
        )

        // Swallow the error intentionally — we only care about logger side-effect
        _ = try? await client.send(UserEndpoint())

        #expect(logger.errorLogCount > 0)
    }

    @Test("logger receives response log call on 2xx response")
    func loggerReceivesResponseCall() async throws {
        let payload = UserPayload(id: "1", name: "Lisa")
        let data = try JSONEncoder().encode(payload)
        let session = MockURLSession(result: .success((data, makeHTTPResponse(statusCode: 200))))
        let logger = RecordingLogger()
        let client: Client = DefaultNetworkClient(
            configuration: makeConfig(session: session, logger: logger)
        )

        _ = try await client.send(UserEndpoint())

        #expect(logger.responseLogCount > 0)
    }

    // MARK: - 5xx → NetworkError.http

    @Test("URLError.cancelled becomes NetworkError.cancelled")
    func cancelledMaps() async {
        let session = MockURLSession(result: .failure(URLError(.cancelled)))
        let client = DefaultNetworkClient(configuration: makeConfig(session: session))
        do {
            _ = try await client.send(UserEndpoint())
            Issue.record("expected NetworkError.cancelled")
        } catch NetworkError.cancelled {
            // expected
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    @Test("response headers preserve Set-Cookie value as a string")
    func responseHeadersFlattenSetCookie() async throws {
        let payload = try JSONEncoder().encode(UserPayload(id: "u1", name: "Homer"))
        let httpResponse = makeHTTPResponse(
            statusCode: 200,
            headers: ["Set-Cookie": "session=abc; Path=/"]
        )
        let session = MockURLSession(result: .success((payload, httpResponse)))
        let client = DefaultNetworkClient(configuration: makeConfig(session: session))

        let response = try await client.send(UserEndpoint())
        let cookie = response.headers.value(forField: "Set-Cookie")
        #expect(cookie == "session=abc; Path=/")
        #expect(cookie?.hasPrefix("[") == false)
    }

    @Test("throws NetworkError.http for 5xx response", arguments: [500, 502, 503])
    func throwsHTTPErrorFor5xx(statusCode: Int) async throws {
        let session = MockURLSession(result: .success((Data(), makeHTTPResponse(statusCode: statusCode))))
        let client: Client = DefaultNetworkClient(
            configuration: makeConfig(session: session, validateHTTPStatus: true)
        )

        var caughtHTTP = false
        do {
            _ = try await client.send(UserEndpoint())
        } catch let error as NetworkError {
            if case .http(let status, _) = error {
                caughtHTTP = true
                #expect(status.statusCode == statusCode)
            }
        }
        #expect(caughtHTTP)
    }
}

// MARK: - Helpers

private func makeHTTPResponse(
    statusCode: Int,
    headers: [String: String] = [:]
) -> HTTPURLResponse {
    HTTPURLResponse(
        url: URL(string: "https://api.example.com/users")!,
        statusCode: statusCode,
        httpVersion: "HTTP/1.1",
        headerFields: headers
    )!
}

private func makeConfig(
    session: any URLSessionProtocol,
    validateHTTPStatus: Bool = true,
    logger: any NetworkLogger = NoopNetworkLogger(),
    reachability: any ReachabilityProviding = AlwaysReachable()
) -> NetworkClientConfiguration {
    NetworkClientConfiguration(
        session: session,
        defaultHeaders: [:],
        defaultTimeout: 10,
        logger: logger,
        validateHTTPStatus: validateHTTPStatus,
        reachability: reachability
    )
}

private struct AlwaysReachable: ReachabilityProviding {
    func isReachable() async -> Bool { true }
}

// MARK: - Test endpoint

private struct UserEndpoint: Endpoint {
    typealias Response = UserPayload
    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String { "/users" }
    var httpMethod: HTTPMethod { .get }
    var task: HTTPTask { .plain }
}

// MARK: - Payload model

private struct UserPayload: Codable, Sendable {
    let id: String
    let name: String
}

// MARK: - Mock URLSession

private struct MockURLSession: URLSessionProtocol {
    let result: Result<(Data, URLResponse), Error>

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        switch result {
        case .success(let tuple): return tuple
        case .failure(let error): throw error
        }
    }
}

// MARK: - Recording logger

private final class RecordingLogger: NetworkLogger, @unchecked Sendable {
    private(set) var requestLogCount = 0
    private(set) var responseLogCount = 0
    private(set) var errorLogCount = 0

    func log(request: URLRequest) {
        requestLogCount += 1
    }

    func log(response: HTTPURLResponse, data: Data) {
        responseLogCount += 1
    }

    func log(error: any Error) {
        errorLogCount += 1
    }
}
