# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **BREAKING**: `HomerFoundation` is now a direct dependency of the core `HomerNetwork` target. Consumers no longer need a separate product to access `FoundationNetworkLogger`.
- `FoundationNetworkLogger` moved from the removed `HomerNetworkFoundation` target into `HomerNetwork` (`Sources/HomerNetwork/Logging/`). Public symbol name unchanged — replace `import HomerNetworkFoundation` with `import HomerNetwork`.

### Removed

- **BREAKING**: `HomerNetworkFoundation` library product and target. Drop the dependency from your `Package.swift`; the single `HomerNetwork` product is sufficient.

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
