# HomerNetwork

Modern Swift 6 / iOS 18 networking library for the Homer suite of Apple apps. Typed endpoints, actor-isolated client, async/await, multipart uploads, pluggable logging — with strict concurrency throughout.

- **Swift tools:** 6.0 (`swiftLanguageModes: [.v6]`, strict concurrency)
- **Platforms:** iOS 18+, macOS 14+
- **Tests:** Swift Testing — 136 tests in 17 suites
- **Status:** `0.6.0` — public API documented with DocC, 0 warnings

## Installation

Swift Package Manager — add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/akkanferhan/HomerNetwork.git", from: "0.6.0")
]
```

Then attach to a target:

```swift
.target(
    name: "MyApp",
    dependencies: ["HomerNetwork"]
)
```

In code:

```swift
import HomerNetwork
```

`HomerNetwork` depends on [HomerFoundation](https://github.com/akkanferhan/HomerFoundation) directly, so `Log`, `Reachability`, and friends are available transitively without a separate product.

## Quick start

Describe each request as an `Endpoint`:

```swift
import HomerNetwork

struct User: Decodable, Sendable {
    let id: Int
    let name: String
}

enum UserAPI: Endpoint {
    case me
    case update(name: String)

    typealias Response = User

    var baseURL: URL { URL(string: "https://api.example.com")! }

    var path: String {
        switch self {
        case .me:        return "/v1/me"
        case .update:    return "/v1/me"
        }
    }

    var httpMethod: HTTPMethod {
        switch self {
        case .me:     return .get
        case .update: return .patch
        }
    }

    var task: HTTPTask {
        switch self {
        case .me:
            return .plain
        case .update(let name):
            return .parameters(body: ["name": name], encoding: .json)
        }
    }
}
```

Then send it:

```swift
let client = NetworkManager()
let response = try await client.send(UserAPI.me)
print(response.value.name)        // decoded User
print(response.status.statusCode) // 200
```

## Modules

### Client — `NetworkClientProtocol` / `NetworkManager`

Actor-isolated client over `URLSession`. Inject anything that conforms to `URLSessionProtocol` to swap the transport in tests:

```swift
let config = NetworkClientConfiguration(
    session: URLSession(configuration: .ephemeral),
    defaultHeaders: ["X-Client": "HomerApp/1.0"],
    defaultTimeout: 30,
    logger: FoundationNetworkLogger(log: Log(subsystem: "com.example.app", category: "network")),
    validateHTTPStatus: true
)
let client = NetworkManager(configuration: config)
```

`validateHTTPStatus` (default `true`) throws `NetworkError.http(status:data:)` for non-2xx responses; flip it off if your backend uses 4xx envelopes you want to decode manually.

### Endpoints — `Endpoint` / `HTTPTask`

`Endpoint` carries `baseURL`, `baseHeaders`, `timeout`, `path`, `httpMethod`, `task`, `headers`, and the `Response` associated type. `HTTPTask` covers four shapes:

```swift
.plain
.parameters(body: [...], encoding: .json, query: [...])
.parametersAndHeaders(body: [...], encoding: .url, query: [...], additionalHeaders: [...])
.multipart(MultipartFormData(parts: [...]))
```

### Encoding — `ParameterEncoding`

```swift
.url            // form-urlencoded body or query
.json           // JSON body
.urlAndJSON     // query items + JSON body
.rawBody(data)  // verbatim bytes
.custom(encoder) // your own ParameterEncoder
```

`URLParameterEncoder` and `JSONParameterEncoder` are public so you can compose them yourself; `NetworkEncodingError` is the failure type (distinct from `Swift.EncodingError`).

### Multipart — `MultipartFormData` / `MultipartPart` / `MimeType`

Type-safe parts: text fields and file fields are different cases of `MultipartPart.Kind`, so you can't accidentally write a filename header for a text value (a real bug in the legacy implementation).

```swift
let form = MultipartFormData(parts: [
    .text(name: "title", value: "Avatar"),
    .file(name: "image", data: imageData, filename: "avatar.png")
])
let task: HTTPTask = .multipart(form)
```

`MimeType` infers from the file extension (case-insensitive); unknown extensions resolve to `.octetStream`.

### Headers — `HTTPHeaders`

Case-insensitive value type that round-trips into `URLRequest.allHTTPHeaderFields`:

```swift
var headers: HTTPHeaders = [
    HTTPHeader.Field.contentType: HTTPHeader.Value.applicationJSON,
    "X-Request-ID": UUID().uuidString
]
headers.set("Bearer …", forField: HTTPHeader.Field.authorization)
```

### Reachability — `ConnectivityProbing`

`NetworkManager` consults its injected `ConnectivityProbing` before every request and throws `NetworkError.offline` when the device reports no usable network path — no transport is attempted, so retries are safe and idempotent.

```swift
public protocol ConnectivityProbing: Sendable {
    func isReachable() async -> Bool
}
```

> Renamed from `ReachabilityProviding` in `0.6.0` to disambiguate from
> `HomerFoundation 0.5.0`'s observable `ReachabilityProviding` protocol
> (a `@MainActor` `Observable` provider with `start()` / `stop()`,
> different shape entirely). A deprecated typealias keeps existing
> call sites compiling for one minor cycle.

The default — `DefaultConnectivityProbe()` — wraps `HomerFoundation.Reachability.currentStatus()` and performs a one-shot `NWPathMonitor` probe per request (~10–50ms). For high-throughput clients, inject a long-lived `HomerFoundation.Reachability` instance with `start()` already called; it conforms to `ConnectivityProbing` directly and reads from a cached observable property:

```swift
import HomerFoundation
import HomerNetwork

let reachability = Reachability()
reachability.start()

let config = NetworkClientConfiguration(reachability: reachability)
let client = NetworkManager(configuration: config)
```

To disable the gate entirely (e.g. in unit tests or when you want to surface raw transport errors), inject a stub returning `true`:

```swift
struct AlwaysReachable: ConnectivityProbing {
    func isReachable() async -> Bool { true }
}
```

### Status & Errors — `HTTPStatus`, `NetworkError`

`HTTPStatus` exposes both the raw code and the `StatusCodeType` semantic bucket. `NetworkError` distinguishes between `.encoding`, `.transport`, `.http`, `.decoding`, `.invalidResponse`, and `.invalidRequest`; the raw `Data` is retained on `.http` and `.decoding` so callers can decode error envelopes.

### Logging — `NetworkLogger`

```swift
public protocol NetworkLogger: Sendable {
    func log(request: URLRequest)
    func log(response: HTTPURLResponse, data: Data)
    func log(error: any Error)
}
```

Bundled implementations:

- `NoopNetworkLogger` — silent (default).
- `FoundationNetworkLogger(log:publicHeaderFields:publicQueryKeys:)` — routes through `HomerFoundation.Log` (itself `os.Logger`-backed) for a unified Homer log signal. Header values and query items are redacted unless their field/key name is in the corresponding allowlist.

## Testing your code

Conform a mock to `URLSessionProtocol` and inject it through `NetworkClientConfiguration`:

```swift
struct MockSession: URLSessionProtocol {
    let payload: (Data, URLResponse)
    func data(for request: URLRequest) async throws -> (Data, URLResponse) { payload }
}
```

Or stub the `NetworkClient` protocol entirely if you want to assert against high-level behavior.

## Roadmap

The current 0.x line is free to break API as the design settles. Items planned before 1.0:

- `RequestInterceptor` middleware pipeline (auth-token injection, refresh, tracing).
- `RetryPolicy` (exponential backoff, idempotent-only retries).
- `ResponseValidator` chain.
- Streaming / download / upload task variants.

## License

MIT — see [LICENSE](LICENSE).
