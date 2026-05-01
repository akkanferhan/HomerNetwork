import Testing
import Foundation
import HomerFoundation
@testable import HomerNetwork

@Suite("NetworkManager retry policy")
struct NetworkManagerRetryTests {

    // MARK: - Retries on transient failure

    @Test("retries 429 then succeeds on 200")
    func retriesAfter429() async throws {
        let session = SequenceMockURLSession(scripted: [
            .success(makeHTTPResult(statusCode: 429, retryAfter: "0")),
            .success(makeHTTPResult(statusCode: 200))
        ])
        let client = NetworkManager(configuration: makeConfig(session: session, retryPolicy: instantPolicy()))

        let response = try await client.send(GetUserEndpoint())
        #expect(response.status.statusCode == 200)
        #expect(await session.callCount == 2)
    }

    @Test("retries until maxAttempts then surfaces last 429")
    func exhaustsRetriesAndThrowsHTTP() async throws {
        let session = SequenceMockURLSession(scripted: Array(repeating:
            .success(makeHTTPResult(statusCode: 429, retryAfter: "0")),
            count: 5
        ))
        let policy = HTTPRetryPolicy(
            maxAttempts: 3,
            baseDelay: 0,
            minDelay: 0,
            maxDelay: 0,
            jitterFactor: 0
        )
        let client = NetworkManager(configuration: makeConfig(session: session, retryPolicy: policy))

        var captured: HTTPStatus?
        do {
            _ = try await client.send(GetUserEndpoint())
        } catch let NetworkError.http(status, _) {
            captured = status
        }
        #expect(captured?.statusCode == 429)
        #expect(await session.callCount == 3, "Three attempts: original + 2 retries")
    }

    @Test("does not retry non-retryable status codes")
    func skipsNonRetryableStatuses() async throws {
        let session = SequenceMockURLSession(scripted: [
            .success(makeHTTPResult(statusCode: 500))
        ])
        let client = NetworkManager(configuration: makeConfig(session: session, retryPolicy: instantPolicy()))

        var caught = false
        do {
            _ = try await client.send(GetUserEndpoint())
        } catch NetworkError.http {
            caught = true
        }
        #expect(caught)
        #expect(await session.callCount == 1)
    }

    // MARK: - Idempotency gate

    @Test("does not retry POST even on 429")
    func skipsRetryForNonIdempotent() async throws {
        let session = SequenceMockURLSession(scripted: [
            .success(makeHTTPResult(statusCode: 429, retryAfter: "0"))
        ])
        let client = NetworkManager(configuration: makeConfig(session: session, retryPolicy: instantPolicy()))

        var caught = false
        do {
            _ = try await client.send(PostUserEndpoint())
        } catch NetworkError.http {
            caught = true
        }
        #expect(caught)
        #expect(await session.callCount == 1, "POST must never auto-retry")
    }

    // MARK: - Disabled retry

    @Test("no retry when retryPolicy is nil")
    func noRetryWithoutPolicy() async throws {
        let session = SequenceMockURLSession(scripted: [
            .success(makeHTTPResult(statusCode: 429, retryAfter: "0"))
        ])
        let client = NetworkManager(configuration: makeConfig(session: session, retryPolicy: nil))

        var caught = false
        do {
            _ = try await client.send(GetUserEndpoint())
        } catch NetworkError.http {
            caught = true
        }
        #expect(caught)
        #expect(await session.callCount == 1)
    }

    // MARK: - Successful first attempt

    @Test("does not invoke session a second time on 200")
    func singleHitOnSuccess() async throws {
        let session = SequenceMockURLSession(scripted: [
            .success(makeHTTPResult(statusCode: 200))
        ])
        let client = NetworkManager(configuration: makeConfig(session: session, retryPolicy: instantPolicy()))

        _ = try await client.send(GetUserEndpoint())
        #expect(await session.callCount == 1)
    }
}

// MARK: - Helpers

private func instantPolicy() -> HTTPRetryPolicy {
    HTTPRetryPolicy(
        maxAttempts: 3,
        baseDelay: 0,
        minDelay: 0,
        maxDelay: 0,
        jitterFactor: 0
    )
}

private func makeHTTPResult(
    statusCode: Int,
    retryAfter: String? = nil
) -> (Data, URLResponse) {
    var headers: [String: String] = [:]
    if let retryAfter {
        headers["Retry-After"] = retryAfter
    }
    let httpResponse = HTTPURLResponse(
        url: URL(string: "https://api.example.com/users")!,
        statusCode: statusCode,
        httpVersion: "HTTP/1.1",
        headerFields: headers
    )!
    let body = statusCode == 200
        ? (try? JSONEncoder().encode(UserPayload(id: "42", name: "Homer"))) ?? Data()
        : Data()
    return (body, httpResponse)
}

private func makeConfig(
    session: any URLSessionProtocol,
    retryPolicy: HTTPRetryPolicy?
) -> NetworkClientConfiguration {
    NetworkClientConfiguration(
        session: session,
        defaultHeaders: [:],
        defaultTimeout: 10,
        logger: NoopNetworkLogger(),
        validateHTTPStatus: true,
        reachability: AlwaysReachable(),
        retryPolicy: retryPolicy
    )
}

private struct AlwaysReachable: ConnectivityProbing {
    func isReachable() async -> Bool { true }
}

// MARK: - Endpoints

private struct GetUserEndpoint: Endpoint {
    typealias Response = UserPayload
    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String { "/users" }
    var httpMethod: HTTPMethod { .get }
    var task: HTTPTask { .plain }
}

private struct PostUserEndpoint: Endpoint {
    typealias Response = UserPayload
    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String { "/users" }
    var httpMethod: HTTPMethod { .post }
    var task: HTTPTask { .plain }
}

private struct UserPayload: Codable, Sendable {
    let id: String
    let name: String
}

// MARK: - Sequence-aware mock session

/// Returns scripted results in order. Wraps around at the end so the
/// "exhaust retries" test doesn't have to predict the exact call count.
private actor SequenceMockURLSession: URLSessionProtocol, Sendable {
    private let scripted: [Result<(Data, URLResponse), Error>]
    private(set) var callCount: Int = 0

    init(scripted: [Result<(Data, URLResponse), Error>]) {
        self.scripted = scripted
    }

    nonisolated func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await record()
    }

    private func record() throws -> (Data, URLResponse) {
        defer { callCount += 1 }
        let index = min(callCount, scripted.count - 1)
        switch scripted[index] {
        case .success(let tuple): return tuple
        case .failure(let error): throw error
        }
    }
}
