# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **BREAKING — public surface significantly reduced.** Symbols listed under "Removed (now internal)" are no longer accessible from importing modules. Refactor as suggested in each entry's migration note below.
- `HTTPHeaders` iteration now yields `(field: String, value: String)` tuples instead of `HTTPHeaders.Entry`. Replace `for entry in headers { … entry.field … }` with `for (field, value) in headers { … field … }`.
- `HTTPStatus.statusType` is no longer public. Use the new convenience properties: `isSuccess` (existing), `isInformational`, `isRedirection`, `isClientError`, `isServerError`.
- `NetworkClientConfiguration`'s stored properties (`session`, `defaultHeaders`, `defaultTimeout`, `logger`, `validateHTTPStatus`, `reachability`) are now `let` instead of `var`. Construct a new configuration to change settings.
- `NetworkClientConfiguration.init`'s `defaultTimeout` default value is now the literal `30` (was `HomerNetworkDefaults.timeoutInterval`). Behavior identical.
- `NetworkClientConfiguration.init`'s `reachability` parameter is now `Optional` with `nil` default; an internal default reachability provider is used when `nil` is passed.

### Added

- `HTTPStatus.isInformational`, `HTTPStatus.isRedirection`, `HTTPStatus.isClientError`, `HTTPStatus.isServerError` convenience properties — replace the now-internal `HTTPStatus.statusType` with category-specific Boolean checks.

### Removed (now internal — was public in 0.3.0)

- `HTTPHeaders.Entry` (struct + `field`, `value`, `init`). Iteration now yields tuples; if you used `Entry` directly, mutate via `set(_:forField:)` instead.
- `HTTPHeaders.merge(_:)` (mutating). Use `merging(_:)` and reassign, or `set(_:forField:)` per entry.
- `StatusCodeType` (enum + cases + `init(statusCode:)`). Use `HTTPStatus.is*` convenience properties.
- `HTTPStatus.statusType`. See above.
- `HomerNetworkDefaults` (enum + `timeoutInterval`). The default timeout is `30` seconds; configure via `NetworkClientConfiguration(defaultTimeout:)`.
- `DefaultReachabilityChecker` (struct + `init`, `isReachable()`). Default reachability provider remains in place; you cannot name its type. To opt out, inject `Reachability(...)` from HomerFoundation or any custom `ReachabilityProviding`.
- `MultipartFormData.makeBoundary()` (static). The default boundary is still generated automatically; pass an explicit `boundary:` argument if you need a custom one.
- `JSONParameterEncoder` (struct + `init`, `encode(_:into:)`). Use `ParameterEncoding.json` (or `.urlAndJSON`) within `HTTPTask.parameters(...)`.
- `URLParameterEncoder` (struct + `init`, `encode(_:into:)`). Use `ParameterEncoding.url` (or `.urlAndJSON`) within `HTTPTask.parameters(...)`. Custom encoding remains possible via `ParameterEncoding.custom(any ParameterEncoder)` — the `ParameterEncoder` protocol stays public.

### Migration cheatsheet

| 0.3.0 | 0.4.0 |
|---|---|
| `for entry in headers { entry.field }` | `for (field, _) in headers { field }` |
| `status.statusType == .clientError` | `status.isClientError` |
| `HomerNetworkDefaults.timeoutInterval` | `30` (literal) |
| `var config = NetworkClientConfiguration(); config.logger = …` | `NetworkClientConfiguration(logger: …)` |
| `JSONParameterEncoder().encode(p, into: &r)` | `HTTPTask.parameters(body: p, encoding: .json)` |
| `URLParameterEncoder().encode(p, into: &r)` | `HTTPTask.parameters(query: p, encoding: .url)` |

## [0.3.0] — 2026-04-26

Complexity-reduction pass: removes duplicate or single-use abstractions, leans on HomerFoundation 0.2.0, and tightens the public surface ahead of 1.0. All notable changes below are source-breaking for 0.2.x consumers — see migration notes.

### Added

- `FoundationNetworkLogger.publicHeaderFields` parameter — header field allowlist that controls debug-level emission of header values, replacing the equivalent feature on the removed `OSLogNetworkLogger`.

### Changed

- **BREAKING**: `Parameters` typealias renamed to `HTTPParameters` (`[String: any Sendable]`). The old name collided with `HomerFoundation.Parameters` (`[String: Any]`); the new name is unambiguous when both modules are imported and binds the type to its HTTP parameter-bag role. Update every `Parameters` reference in endpoint definitions, custom encoders, and call sites.
- **BREAKING**: `API` protocol folded into `Endpoint`. Conformers that referenced `API` directly (rare — usually only as a supertype) must conform to `Endpoint` instead. The required properties (`baseURL`, `baseHeaders`, `timeout`) are unchanged.
- HomerFoundation dependency requirement bumped to `0.2.0`. `URLParameterEncoder` now uses `HomerFoundation.AnyOptional` for `nil` detection; `MultipartFormData` now uses `HomerFoundation.Data.append(_:encoding:)` for UTF-8 byte appends.
- Renamed the testing SPI from `@_spi(HomerNetworkInternal)` to `@_spi(Testing)` to match Swift's emerging community convention. Test targets that imported via the old SPI must update their `@_spi(...)` import to `@_spi(Testing)`.

### Renamed

- `EncodingError` → `NetworkEncodingError`. The legacy name shadowed Swift's standard library `EncodingError` (raised by `Encoder` implementations); the new name is unambiguous and signals that the type covers parameter and multipart serialization failures, not `Codable` failures.

### Fixed

- Filled in DocC comments on previously undocumented public symbols across the surface (`HTTPHeaders`, `HTTPHeader.Field` / `.Value`, `HTTPMethod`, `HTTPStatus`, `MimeType`, `MultipartFormData`, `MultipartPart`, `NetworkResponse`, `NetworkClient`, `NetworkClientConfiguration`, `URLSessionProtocol`, `NetworkError.description`).
- Updated stale DocC cross-references left over from the `API` → `Endpoint` merge and the `Parameters` rename (now `HTTPParameters`).

### Removed

- **BREAKING**: `OSLogNetworkLogger`. Replace with `FoundationNetworkLogger(log: Log(subsystem: "...", category: "..."), publicHeaderFields: [...], publicQueryKeys: [...])` — `Log` is itself `os.Logger`-backed, so log destinations and privacy semantics are preserved.
- **BREAKING**: `API` protocol. Use `Endpoint` directly (see above).
- **BREAKING**: `Parameters` typealias. Use `HTTPParameters` (see above).
- **BREAKING**: `URLSanitizer` made internal. Third-party loggers should perform their own sanitization or live in this module.
- **BREAKING**: `NetworkLoggerFormat` made internal. Was only consumed by bundled loggers.
- **BREAKING**: `HTTPStatusRange` made private (now nested as `StatusCodeType.Range`). Was only consumed by `StatusCodeType.init(statusCode:)`.
- **BREAKING**: Default empty implementations of `NetworkLogger.log(response:data:)` and `NetworkLogger.log(error:)`. All three methods are now required so silent overrides are explicit; conform to `NoopNetworkLogger` (or implement them as `{}`) for a no-op logger.
- Internal `AnyOptionalProtocol` in `URLParameterEncoder.swift` — replaced by `HomerFoundation.AnyOptional`.

### Migration from 0.2.x

1. **`Parameters` → `HTTPParameters`** — search-and-replace across endpoint enums, custom `ParameterEncoder` conformers, and `HTTPTask.parameters(...)` call sites. The value type (`[String: any Sendable]`) is unchanged.
2. **`API` protocol** — drop the explicit conformance; `Endpoint` already requires (and provides defaults for) `baseURL`, `baseHeaders`, `timeout`.
3. **`OSLogNetworkLogger`** — replace
   ```swift
   OSLogNetworkLogger(subsystem: "com.example.app", category: "network", publicHeaderFields: [.contentType])
   ```
   with
   ```swift
   FoundationNetworkLogger(
       log: Log(subsystem: "com.example.app", category: "network"),
       publicHeaderFields: [HTTPHeader.Field.contentType]
   )
   ```
4. **Custom `NetworkLogger` conformer** — implement `log(response:data:)` and `log(error:)` explicitly (no more empty defaults). Add `func log(response:_:_) {}` / `func log(error:_) {}` if a no-op is desired.
5. **`URLSanitizer` / `NetworkLoggerFormat`** — if you reached into either of these (very unusual outside the library), copy the constants you needed into your own code.
6. **`EncodingError` → `NetworkEncodingError`** — rename the type at every catch site. Cases (`missingURL`, `jsonSerializationFailed(underlying:)`, `multipartFailure(_:)`) are unchanged.
7. **Testing SPI** — if a test target imported `RequestBuilder` via `@_spi(HomerNetworkInternal) @testable import HomerNetwork`, change the SPI name to `@_spi(Testing)`.

## [0.2.0] — 2026-04-26

Folds `HomerNetworkFoundation` into the core target and introduces an always-on reachability pre-flight gate. Both changes are source-breaking for 0.1.x consumers — see migration notes below.

### Added

- `ReachabilityProviding` protocol — `Sendable` async gate consulted by `DefaultNetworkClient` before every request.
- `DefaultReachabilityChecker` — default conformance wrapping `HomerFoundation.Reachability.currentStatus()` for one-shot probing.
- `Reachability: ReachabilityProviding` extension — long-lived observable reachability instances can be injected directly for cached, hot-path-friendly checks.
- `NetworkClientConfiguration.reachability` — injection point for the gate; defaults to `DefaultReachabilityChecker()`.
- `NetworkError.offline` — thrown when the pre-flight reachability check fails. No transport hop is performed, so retries are safe.

### Changed

- **BREAKING**: `HomerFoundation` is now a direct dependency of the core `HomerNetwork` target. Consumers no longer need a separate product to access `FoundationNetworkLogger`.
- `FoundationNetworkLogger` moved from the removed `HomerNetworkFoundation` target into `HomerNetwork` (`Sources/HomerNetwork/Logging/`). Public symbol name unchanged — replace `import HomerNetworkFoundation` with `import HomerNetwork`.
- `DefaultNetworkClient` now performs a reachability check before every request and throws `NetworkError.offline` when the configured `ReachabilityProviding` reports unreachable. Inject a stub returning `true` (e.g. in unit tests or replay sessions) to bypass the gate.

### Removed

- **BREAKING**: `HomerNetworkFoundation` library product and target. Drop the dependency from your `Package.swift`; the single `HomerNetwork` product is sufficient.

### Migration from 0.1.x

1. Drop the `HomerNetworkFoundation` product reference from your `Package.swift` `dependencies`. The single `HomerNetwork` product is sufficient.
2. Replace `import HomerNetworkFoundation` with `import HomerNetwork`. `FoundationNetworkLogger` is unchanged in shape.
3. Add `case .offline:` (or a `default` arm) to any exhaustive `switch` over `NetworkError`. To preserve pre-0.2.0 behavior (no gate), inject a `ReachabilityProviding` stub returning `true`.

## [0.1.0] — 2026-04-25

Initial public release. Modern Swift 6 / iOS 18 networking layer extracted from the legacy `BtcTurkCase` project, redesigned with strict concurrency, async/await, actor isolation, and Swift Testing.

### Added

- **Client** — `NetworkClient` protocol and `DefaultNetworkClient` actor with `send(_:)` for typed `Endpoint`s. `NetworkClientConfiguration` for injecting `URLSession`, default headers, default timeout, logger, and HTTP-status validation toggle. `URLSessionProtocol` so tests can swap the transport.
- **Endpoints** — `API` and `Endpoint` protocols with associated `Response: Decodable & Sendable`. `HTTPTask` enum: `.plain`, `.parameters`, `.parametersAndHeaders`, `.multipart`. Default `decoder` and merged `allHeaders`.
- **Encoding** — `ParameterEncoder` protocol, `URLParameterEncoder`, `JSONParameterEncoder`. `ParameterEncoding` enum: `.url`, `.json`, `.urlAndJSON`, `.rawBody(Data)`, `.custom(any ParameterEncoder)`. `NetworkEncodingError` distinct from Foundation's `EncodingError`.
- **Multipart** — `MultipartPart` (text/file kinds), `MultipartFormData` (encode + content-type), `MimeType` with extension inference and an open-ended fallback (`.octetStream` instead of `assertionFailure`).
- **Headers** — `HTTPHeaders` value type: case-insensitive lookup, dictionary literal init, `merge`/`merging`, sequence conformance. `HTTPHeader.Field` and `HTTPHeader.Value` constants.
- **Status** — `HTTPStatus` and `StatusCodeType` (informational/success/redirection/clientError/serverError/unrecognized).
- **Errors** — `NetworkError`: `.invalidRequest`, `.encoding`, `.transport`, `.http(status:data:)`, `.decoding(_,data:)`, `.invalidResponse`. Raw response data is preserved on `.http` and `.decoding` so callers can decode error envelopes.
- **Logging** — `NetworkLogger` protocol with `NoopNetworkLogger` and `OSLogNetworkLogger` implementations. The latter redacts unknown header values by default.
- **HomerNetworkFoundation** — optional product wiring `HomerFoundation.Log` into `NetworkLogger` via `FoundationNetworkLogger`. The core `HomerNetwork` library has zero transitive dependencies.
- **Tests** — 91 Swift Testing tests across 11 suites, covering header semantics, status mapping, MIME inference, multipart encoding, parameter encoding, request building, and the full client request/response/error matrix with a mock `URLSessionProtocol`.

### Project conventions

- Strict Swift 6 concurrency throughout; all public types are `Sendable`.
- `Parameters = [String: any Sendable]` — the legacy `[String: Any]` shape is replaced; call sites must use `Sendable` values.
- `actor`-isolated client; consumers stub via the `NetworkClient` protocol.
- Public API documented with DocC comments on every symbol.

### Migration from legacy `BtcTurkCase` network layer

| Old | New |
|------|------|
| `NetworkManager().genericFetch(_:)` | `DefaultNetworkClient().send(_:)` |
| `Parameters = [String: Any]` | `Parameters = [String: any Sendable]` |
| `requestParametersAndHeaders` | `.parametersAndHeaders` |
| `getMimeType()` | `MimeType(extension:)` |
| `additionHeaders` | `additionalHeaders` |
| `statucCode` | `statusCode` |
| `unRecognizedError` | `unrecognized` |
| Multipart text + file in one protocol | `MultipartPart.Kind.text` / `.file` |

[Unreleased]: https://github.com/akkanferhan/HomerNetwork/compare/0.3.0...HEAD
[0.3.0]: https://github.com/akkanferhan/HomerNetwork/releases/tag/0.3.0
[0.2.0]: https://github.com/akkanferhan/HomerNetwork/releases/tag/0.2.0
[0.1.0]: https://github.com/akkanferhan/HomerNetwork/releases/tag/0.1.0
