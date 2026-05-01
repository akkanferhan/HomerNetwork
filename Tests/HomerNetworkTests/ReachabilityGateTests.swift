import Testing
import Foundation
@testable import HomerNetwork

@Suite("ReachabilityGate")
struct ReachabilityGateTests {

    @Test("throws NetworkError.offline when reachability reports unreachable")
    func throwsOfflineWhenUnreachable() async throws {
        let session = TripwireURLSession()
        let config = NetworkClientConfiguration(
            session: session,
            defaultHeaders: [:],
            defaultTimeout: 10,
            logger: NoopNetworkLogger(),
            validateHTTPStatus: true,
            reachability: NeverReachable()
        )
        let client: any NetworkClientProtocol = NetworkManager(configuration: config)

        var caughtOffline = false
        do {
            _ = try await client.send(GateEndpoint())
        } catch let error as NetworkError {
            if case .offline = error { caughtOffline = true }
        }
        #expect(caughtOffline, "Expected NetworkError.offline to be thrown")
    }

    @Test("does not invoke transport when reachability reports unreachable")
    func skipsTransportWhenUnreachable() async throws {
        let session = TripwireURLSession()
        let config = NetworkClientConfiguration(
            session: session,
            defaultHeaders: [:],
            defaultTimeout: 10,
            logger: NoopNetworkLogger(),
            validateHTTPStatus: true,
            reachability: NeverReachable()
        )
        let client: any NetworkClientProtocol = NetworkManager(configuration: config)

        _ = try? await client.send(GateEndpoint())

        #expect(await session.invocationCount == 0, "Transport should not be touched when offline")
    }

    @Test("logs the offline error through the configured logger")
    func logsOfflineError() async throws {
        let logger = OfflineLogger()
        let config = NetworkClientConfiguration(
            session: TripwireURLSession(),
            defaultHeaders: [:],
            defaultTimeout: 10,
            logger: logger,
            validateHTTPStatus: true,
            reachability: NeverReachable()
        )
        let client: any NetworkClientProtocol = NetworkManager(configuration: config)

        _ = try? await client.send(GateEndpoint())

        #expect(logger.snapshot().count == 1)
        #expect(logger.snapshot().lastDescription == "NetworkError.offline")
    }

    @Test("offline gate fires before a cancelled task is observed")
    func cancelledTaskOfflineGate() async throws {
        let session = TripwireURLSession()
        let config = NetworkClientConfiguration(
            session: session,
            defaultHeaders: [:],
            defaultTimeout: 10,
            logger: NoopNetworkLogger(),
            validateHTTPStatus: true,
            reachability: NeverReachable()
        )
        let client: any NetworkClientProtocol = NetworkManager(configuration: config)

        let task = Task<Void, Error> {
            _ = try await client.send(GateEndpoint())
        }
        task.cancel()

        var caughtExpected = false
        do {
            try await task.value
        } catch let error as NetworkError {
            switch error {
            case .offline, .cancelled:
                caughtExpected = true
            default:
                Issue.record("Expected .offline or .cancelled, got \(error)")
            }
        }
        #expect(caughtExpected, "Either NetworkError.offline or NetworkError.cancelled is acceptable")
        #expect(await session.invocationCount == 0, "Transport must remain untouched")
    }

    @Test("performs the request normally when reachability reports reachable")
    func proceedsWhenReachable() async throws {
        let payload = GatePayload(value: "ok")
        let data = try JSONEncoder().encode(payload)
        let response = HTTPURLResponse(
            url: URL(string: "https://api.example.com/gate")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        let session = ScriptedURLSession(payload: (data, response))
        let config = NetworkClientConfiguration(
            session: session,
            defaultHeaders: [:],
            defaultTimeout: 10,
            logger: NoopNetworkLogger(),
            validateHTTPStatus: true,
            reachability: AlwaysReachable()
        )
        let client: any NetworkClientProtocol = NetworkManager(configuration: config)

        let result = try await client.send(GateEndpoint())

        #expect(result.value.value == "ok")
        #expect(await session.invocationCount == 1)
    }
}

// MARK: - Stubs

private struct AlwaysReachable: ConnectivityProbing {
    func isReachable() async -> Bool { true }
}

private struct NeverReachable: ConnectivityProbing {
    func isReachable() async -> Bool { false }
}

private struct GatePayload: Codable, Sendable {
    let value: String
}

private struct GateEndpoint: Endpoint {
    typealias Response = GatePayload
    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String { "/gate" }
    var httpMethod: HTTPMethod { .get }
    var task: HTTPTask { .plain }
}

private actor TripwireURLSession: URLSessionProtocol {
    private(set) var invocationCount = 0

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        invocationCount += 1
        throw URLError(.unknown)
    }
}

private actor ScriptedURLSession: URLSessionProtocol {
    private let payload: (Data, URLResponse)
    private(set) var invocationCount = 0

    init(payload: (Data, URLResponse)) {
        self.payload = payload
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        invocationCount += 1
        return payload
    }
}

private final class OfflineLogger: NetworkLogger, @unchecked Sendable {
    struct Snapshot {
        let count: Int
        let lastDescription: String?
    }

    private let lock = NSLock()
    private var errorCount = 0
    private var lastErrorDescription: String?

    func log(request: URLRequest) {}
    func log(response: HTTPURLResponse, data: Data) {}

    func log(error: any Error) {
        lock.lock()
        defer { lock.unlock() }
        errorCount += 1
        lastErrorDescription = String(describing: error)
    }

    func snapshot() -> Snapshot {
        lock.lock()
        defer { lock.unlock() }
        return Snapshot(count: errorCount, lastDescription: lastErrorDescription)
    }
}
