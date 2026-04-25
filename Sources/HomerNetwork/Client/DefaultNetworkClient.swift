import Foundation

/// The default ``NetworkClient`` implementation.
///
/// Built on top of `URLSession` (or any ``URLSessionProtocol`` you inject).
/// `actor` isolation means concurrent ``send(_:)`` calls don't race over
/// shared mutable state and keeps the door open for in-flight tracking,
/// request deduplication, and authentication refresh in future versions.
public actor DefaultNetworkClient: NetworkClient {
    private let configuration: NetworkClientConfiguration
    private let builder = RequestBuilder()

    public init(configuration: NetworkClientConfiguration = NetworkClientConfiguration()) {
        self.configuration = configuration
    }

    public func send<E: Endpoint>(_ endpoint: E) async throws -> NetworkResponse<E.Response> {
        guard await configuration.reachability.isReachable() else {
            configuration.logger.log(error: NetworkError.offline)
            throw NetworkError.offline
        }

        let request: URLRequest
        do {
            request = try builder.makeRequest(
                for: endpoint,
                defaultHeaders: configuration.defaultHeaders,
                defaultTimeout: configuration.defaultTimeout
            )
        } catch let error as NetworkEncodingError {
            configuration.logger.log(error: error)
            throw NetworkError.encoding(error)
        } catch {
            configuration.logger.log(error: error)
            throw NetworkError.invalidRequest
        }

        configuration.logger.log(request: request)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await configuration.session.data(for: request)
        } catch {
            configuration.logger.log(error: error)
            if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                throw NetworkError.cancelled
            }
            throw NetworkError.transport(SendableErrorBox(error))
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        configuration.logger.log(response: httpResponse, data: data)

        let status = HTTPStatus(httpURLResponse: httpResponse)
        let headers = HTTPHeaders(httpResponse.responseHeaders)

        if configuration.validateHTTPStatus, !status.isSuccess {
            throw NetworkError.http(status: status, data: data)
        }

        do {
            let value = try endpoint.decoder.decode(E.Response.self, from: data)
            return NetworkResponse(value: value, status: status, headers: headers, data: data)
        } catch {
            configuration.logger.log(error: error)
            throw NetworkError.decoding(SendableErrorBox(error), data: data)
        }
    }
}

/// Wraps an arbitrary `Error` as a `Sendable` value so it can flow through
/// ``NetworkError`` cases that require `any Error & Sendable`.
///
/// `@unchecked Sendable` is safe here because the snapshot is captured
/// eagerly at `init` time as an immutable Swift `String`, and the
/// original `Error` reference is not retained — so there is nothing
/// mutable for a concurrent reader to observe.
private struct SendableErrorBox: Error, @unchecked Sendable, CustomStringConvertible {
    /// Eager snapshot of the underlying `String(describing:)` rendering.
    let snapshot: String

    init(_ error: any Error) {
        self.snapshot = String(describing: error)
    }

    var description: String { snapshot }
}

private extension HTTPURLResponse {
    /// `allHeaderFields` is `[AnyHashable: Any]`; this distills it into a
    /// `[String: String]` matching what `URLRequest.allHTTPHeaderFields` accepts.
    ///
    /// Multi-value headers (which arrive as `NSArray` from `URLSession`,
    /// notably `Set-Cookie`) are joined with `, ` per RFC 7230 §3.2.2 so
    /// callers don't see `"["a=1", "b=2"]"` debug-formatted output.
    var responseHeaders: [String: String] {
        var result: [String: String] = [:]
        for (key, value) in allHeaderFields {
            guard let field = key as? String else { continue }
            if let array = value as? [Any] {
                result[field] = array.map { String(describing: $0) }.joined(separator: ", ")
            } else if let string = value as? String {
                result[field] = string
            } else {
                result[field] = String(describing: value)
            }
        }
        return result
    }
}
