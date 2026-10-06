# Caching and token storage

Sources of truth: `DefaultURLSession.swift`, `APIRequest.swift`,
`AccessTokenStore.swift`, `TokenRefreshing.swift`, and
`URLSessionAPIClient.swift`.

## HTTP response caching

**This package does not implement application-level response caching.**

There is no `URLCache` configuration, no in-memory response store, and no
ETag / `If-None-Match` / `If-Modified-Since` conditional-request logic in
`Sources/IlkerSevimNetworking`.

What *does* exist:

| Piece | Behavior |
| --- | --- |
| `DefaultURLSession.makeDefault()` | Builds one process-wide `URLSession` from `URLSessionConfiguration.default`, then sets request timeout `30`, resource timeout `60`, and `waitsForConnectivity = true`. It does **not** set `urlCache`, `requestCachePolicy`, or related fields. |
| `APIRequest.urlRequest(bearerToken:)` | Builds a `URLRequest` with method, body, `timeoutInterval = 30`, optional `Idempotency-Key`, and optional `Authorization`. It does **not** set `cachePolicy`. |
| System defaults | Because configuration starts from `.default` and `URLRequest` is left at its default cache policy, Foundation’s usual shared-cache / protocol-cache-policy behavior applies unless the host replaces the session. The package never documents or customizes that path. |

Hosts that need a controlled cache should inject their own `URLSession` into
`URLSessionAPIClient(session:…)`. Tests use
`URLSessionConfiguration.ephemeral` with `StubURLProtocol`
(`Tests/IlkerSevimNetworkingTests/StubURLProtocol.swift`), which also avoids
relying on disk cache.

## Token storage

### `AccessTokenStore` (`AccessTokenStore.swift`)

Protocol (nonisolated, `Sendable`):

- `loadAccessToken() throws -> String?`
- `saveAccessToken(_:) throws`
- `clearAccessToken() throws`

Errors: `AccessTokenStoreError.keychainStatus(OSStatus)`.

### `InMemoryAccessTokenStore`

Demo/test store. Holds a single optional `String` behind `NSLock`
(`@unchecked Sendable`). Not Keychain-backed. Initializer accepts
`initialToken`.

### `KeychainAccessTokenStore`

App-private generic-password item (`kSecClassGenericPassword`):

- Defaults: `service = "com.ilkersevim.networking.token"`,
  `account = "access-token"`.
- Accessibility: `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- Update-then-add on save; treat `errSecItemNotFound` as success on clear.
- **Not** a shared access group — no Keychain Sharing entitlement required
  (stated in the type’s doc comment).

## Token refresh

### Protocols and production default

`TokenRefreshing` (`TokenRefreshing.swift`):

- `currentAccessToken() async -> String?`
- `refreshAccessToken() async throws -> String`

`EmptyTokenRefresher` (struct): always returns `nil` from
`currentAccessToken()`, and `refreshAccessToken()` throws
`APIError.unauthorizedAfterRefresh`. This is the
`URLSessionAPIClient` default refresher.

### Client integration (`URLSessionAPIClient.send`)

1. Read `token = await tokenRefresher.currentAccessToken()` once per `send`.
2. On HTTP **401**, if a refresh has not yet been attempted for this call
   (`didRefreshToken == false`), set the flag, call
   `refreshAccessToken()`, replace `token`, and `continue` the loop
   (same attempt counter — refresh is not counted as a retry attempt).
3. A second 401 after refresh throws
   `APIError.unauthorizedAfterRefresh` immediately (no further refresh).

That is **one-shot refresh per `send` invocation**, not a global auth
coordinator.

### Demo refreshers (actors)

| Type | Role |
| --- | --- |
| `InMemoryDemoTokenRefresher` | Actor holding `accessToken` / `refreshedToken`; increments `refreshCount` on refresh. |
| `KeychainDemoTokenRefresher` | Actor over any `AccessTokenStore`; seeds once from `seedToken` if the store is empty; refresh writes `refreshedToken` into the store. Store failures become `APIError.unauthorizedAfterRefresh`. |

Both are explicitly demo/portfolio helpers (fixed demo strings), not OAuth
clients.

## Concurrency: actors vs single-flight

**What exists**

- `InMemoryDemoTokenRefresher` and `KeychainDemoTokenRefresher` are
  **`actor`s**, so calls on a *single* refresher instance are serialized by
  the actor executor.
- `InMemoryAccessTokenStore` uses `NSLock` around the in-memory token.
- `URLSessionAPIClient` itself is a **`struct`**, not an actor; concurrent
  `send` calls share the injected refresher/session without additional
  client-side locking.

**What does not exist**

- No single-flight / coalesced refresh (no shared “refresh in progress” task,
  no waiter list, no `Task` memoization across concurrent 401s).
- Concurrent `send` calls that each observe 401 can each call
  `refreshAccessToken()` once (each call has its own `didRefreshToken`
  flag). Actor isolation only orders those refreshes; it does not collapse
  them into one network refresh.

Hosts that need single-flight refresh must implement it inside a custom
`TokenRefreshing` type.

## Tests

| Behavior | Test |
| --- | --- |
| Empty refresher | `TokenRefreshingTests.emptyRefresherHasNoTokenAndFailsRefresh` |
| In-memory demo refresh | `TokenRefreshingTests.inMemoryDemoRefresherUpdatesAccessToken` |
| Demo refresher + store | `TokenRefreshingTests.keychainDemoRefresherPersistsThroughStore` (uses `InMemoryAccessTokenStore`) |
| Keychain round-trip | `TokenRefreshingTests.keychainAccessTokenStoreRoundTrips` |
| One-shot 401 refresh in client | `URLSessionAPIClientTests` → `refreshesTokenOnceThenRetriesOriginalRequest` |

### Gaps

- No tests for HTTP cache policy, `URLCache`, or conditional requests (none
  implemented).
- No concurrent multi-`send` refresh / single-flight tests.
- No test that a second 401 after refresh throws
  `APIError.unauthorizedAfterRefresh`.
