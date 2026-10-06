# Design decisions and trade-offs

Sources of truth: `Package.swift`, `IlkerSevimNetworking.podspec`, and the
types under `Sources/IlkerSevimNetworking/`.

## Foundation-only on URLSession async/await

The package has **no external Swift dependencies**. `Package.swift` declares
only the library and test targets. The podspec links `Foundation` and
`Security` only.

Networking I/O goes through `URLSession.data(for:)` inside
`URLSessionAPIClient.perform(_:bearerToken:)`. That choice keeps the stack
aligned with Swift concurrency (`async`/`await`, `Task` cancellation) without
Alamofire, Combine wrappers, or a custom socket layer.

Trade-offs accepted in code:

- Features such as upload progress, multipart helpers, or request adapters are
  absent — hosts build on `APIRequest` + `APIClient`.
- Cache / ETag behavior is left to Foundation defaults or a host-supplied
  `URLSession` (see [caching-and-tokens.md](caching-and-tokens.md)).
- Logging is opt-in via `APILogging` / `RedactedAPILogger` (os.Logger), never
  logging Authorization or bodies.

## Actor and isolation choices

| Type | Isolation | Why it looks that way in code |
| --- | --- | --- |
| `URLSessionAPIClient` | `struct` (`Sendable` via `APIClient`) | Stateless wrapper around injected session/policy/refresher/logger/sleeper; no mutable client state beyond per-`send` locals. |
| `APIRequest`, `HTTPMethod`, `APIError`, `APIResponse`, `RetryPolicy`, `EmptyTokenRefresher` | `nonisolated` value types | Doc comment on `APIRequest` notes staying usable under `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor` without hopping to the main actor. |
| `InMemoryDemoTokenRefresher`, `KeychainDemoTokenRefresher` | `actor` | Mutable demo token / seed state; actor serializes access on one instance. |
| `InMemoryAccessTokenStore` | `final class` + `NSLock`, `@unchecked Sendable` | Synchronous Keychain-shaped API (`throws`, not `async`); lock instead of actor. |
| `KeychainAccessTokenStore` | `struct` | Thin SecItem wrapper; no in-process mutable fields beyond service/account strings. |
| `DefaultURLSession` | `enum` namespace + private static `sharedSession` | One process-wide session to avoid leaking sessions from repeated `makeDefault()` calls. |

There is no package-wide “networking actor.” Concurrency safety is compositional:
`Sendable` value types, actor demo refreshers, and lock-backed store.

## Error modelling

`APIError` is a flat `Error` / `Equatable` / `LocalizedError` / `Sendable`
enum:

- `invalidResponse` — non-`HTTPURLResponse` (or unknown catch-all).
- `transport(URLError.Code)` — mapped from non-cancel `URLError`.
- `httpStatus(Int)` — non-2xx that is not handled as 401-refresh.
- `unauthorizedAfterRefresh` — second 401, or empty/demo refresh failure.
- `decodingFailed` — **declared but unused** by this package (no decoder
  helpers here; reserved for hosts).
- `cancelled` — **declared but unused** by `URLSessionAPIClient`; live cancel
  paths throw `CancellationError` instead (see
  [cancellation.md](cancellation.md)).

Retry classification lives in `RetryPolicy.shouldRetry`, not inside each
throw site: only selected transport codes and HTTP 429/5xx, and only when
`APIRequest.isRetrySafe` (GET/PUT/DELETE always; POST only with non-empty
`idempotencyKey`).

## Platform minimums

Declared identically in SPM and CocoaPods:

| Platform | Minimum |
| --- | --- |
| iOS | 17.0 (`Package.swift` `.iOS(.v17)`, podspec `17.0`) |
| macOS | 14.0 (`.macOS(.v14)`, podspec `14.0`) |
| watchOS | 10.0 (`.watchOS(.v10)`, podspec `10.0`) |

Swift tools / language: `swift-tools-version: 5.9`, podspec
`s.swift_versions = ['5.9']`.

Those floors match modern concurrency + `URLSession` async APIs used by the
client without availability gymnastics in source. Older OS versions are out of
scope for this package as written.

## Session factory defaults

`DefaultURLSession` intentionally shares one `URLSession` and sets:

- `timeoutIntervalForRequest = 30` (aligned with `APIRequest`’s
  `timeoutInterval = 30`)
- `timeoutIntervalForResource = 60`
- `waitsForConnectivity = true`

Hosts can ignore `makeDefault()` and pass any `URLSession` into
`URLSessionAPIClient`.
