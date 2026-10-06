# How it is tested

Sources of truth: `Tests/IlkerSevimNetworkingTests/` and
`.github/workflows/ci.yml`.

## Test layout

Swift Testing (`import Testing`) under target `IlkerSevimNetworkingTests`
(`Package.swift`). HTTP is stubbed with `StubURLProtocol` +
`StubURLProtocolGate` / `StubSessionRegistry`
(`StubURLProtocol.swift`) — ephemeral sessions, queued response/error stubs,
per-session request counts.

## Behavior → test map

### `URLSessionAPIClientTests` (`URLSessionAPIClientTests.swift`)

Suite: `"URLSession API client"`. One `@Test`,
`exercisesRetryAuthAndFailureMapping`, which runs four private scenarios:

| Scenario (private method) | Behavior under test | Production types |
| --- | --- | --- |
| `refreshesTokenOnceThenRetriesOriginalRequest` | 401 then 200; refresher called once; two HTTP attempts | `URLSessionAPIClient`, `TokenRefreshing`, 401 branch in `send` |
| `respectsRetryAfterForRateLimit` | 429 with `Retry-After: 1` then 200; sleeper records `1_000_000_000` ns | `RetryPolicy.delayNanoseconds`, `waitBeforeRetry` |
| `mapsTransportAndHTTPFailures` | `URLError.timedOut` → `APIError.transport(.timedOut)`; HTTP 400 → `APIError.httpStatus(400)` | error mapping in `send` |
| `preservesCancellationError` | Cancelled `Task` → `CancellationError`; stubbed `URLError(.cancelled)` → `CancellationError` | cancel catches in `send` |

Helpers: `NoopAPILogger`, `TestRetrySleeper` (actor), `TestTokenRefresher`
(actor) — test doubles only.

### `RetryPolicyTests` (`RetryPolicyTests.swift`)

Suite: `"Retry policy"`.

| Test | Behavior |
| --- | --- |
| `classifiesRetryableAndNonRetryableFailures` | `timedOut` / 503 retryable; 404 not; attempt `== maxAttempts` not |
| `postRetriesOnlyWithIdempotencyKey` | POST without key not retry-safe; with `idempotencyKey` is |
| `retryAfterHeaderBeatsExponentialBackoff` | Numeric `Retry-After` preferred over exponential base |
| `retryAfterRejectsNonFiniteAndOversizedValues` | `inf` / `-inf` / `nan` fall back; huge values clamp to `maxDelayNanoseconds` |
| `exponentialBackoffSaturatesWithoutOverflow` | Large attempt multipliers stay within `maxDelayNanoseconds` |

### `TokenRefreshingTests` (`TokenRefreshingTests.swift`)

Suite: `"Token refreshing"`.

| Test | Behavior |
| --- | --- |
| `emptyRefresherHasNoTokenAndFailsRefresh` | `EmptyTokenRefresher` nil token + `unauthorizedAfterRefresh` |
| `inMemoryDemoRefresherUpdatesAccessToken` | `InMemoryDemoTokenRefresher` rotate + `refreshCount` |
| `keychainDemoRefresherPersistsThroughStore` | `KeychainDemoTokenRefresher` + `InMemoryAccessTokenStore` seed/rotate |
| `keychainAccessTokenStoreRoundTrips` | Real `KeychainAccessTokenStore` save/load/update/clear (unique service/account UUID) |

## CI

Workflow: [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)
(name **CI**). Triggers: `push` / `pull_request` to `main`.

| Job (`name`) | Runner | Steps that matter |
| --- | --- | --- |
| `build-and-test` (**Build and Test**) | `macos-latest` | `swift --version`, `swift build`, `swift test` |
| `pod-lib-lint` (**Pod Lib Lint**) | `macos-latest` | latest-stable Xcode, `gem install cocoapods`, `pod lib lint IlkerSevimNetworking.podspec --allow-warnings --platforms=ios,osx,watchos` |

Separate publish workflow
[`.github/workflows/publish-cocoapods.yml`](../.github/workflows/publish-cocoapods.yml)
runs `pod trunk push` on semver tags / `workflow_dispatch`; it is **not** a
PR validation job.

## Gaps

Honest holes relative to the production surface:

| Area | Gap |
| --- | --- |
| Cancellation | No cancel-during-backoff sleep test |
| Auth | No test for second 401 → `unauthorizedAfterRefresh` |
| Auth concurrency | No multi-`send` / single-flight refresh test (API also lacks single-flight) |
| Caching | No `URLCache` / cache-policy / ETag tests (none implemented) |
| `APIError` | `decodingFailed` and `cancelled` cases unexercised by client tests |
| Logging / session | No direct tests for `RedactedAPILogger` or `DefaultURLSession.makeDefault()` |
| Retry policy | `APIError.cancelled` / `.decodingFailed` non-retry branches not asserted |
| Platforms | CI `swift test` is macOS host; pod lint covers iOS/macOS/watchOS packaging, not a full matrix of `swift test` on every OS |
| DocC | No `.docc` catalog in the package; markdown under `docs/` is the review docs surface |
