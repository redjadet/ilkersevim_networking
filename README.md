# IlkerSevimNetworking

Foundation-only Swift networking helpers extracted from
[`redjadet/super_demo_ios`](https://github.com/redjadet/super_demo_ios)
(`superDemoApp/Shared/Networking`).

**URLSession** client with retry (backoff, jitter, `Retry-After`),
idempotent-POST gating via `Idempotency-Key`, one-shot 401 token refresh,
and redacted host/status logging.

## Requirements

- iOS 17+ / macOS 14+ / watchOS 10+
- Swift 5.9+

## Install

### Swift Package Manager (primary)

```swift
dependencies: [
  .package(url: "https://github.com/redjadet/ilkersevim_networking.git", from: "1.0.0")
]
```

```swift
import IlkerSevimNetworking

let client = URLSessionAPIClient(
  session: DefaultURLSession.makeDefault(),
  logger: RedactedAPILogger(subsystem: "com.example.app")
)
let response = try await client.send(APIRequest(url: url))
```

### CocoaPods

```ruby
pod 'IlkerSevimNetworking', '~> 1.0'
```

Podspec is in-repo. Trunk publish may lag the GitHub tag; SPM is canonical.

## Public API

| Type | Role |
| --- | --- |
| `HTTPMethod`, `APIRequest` | Typed request + idempotency |
| `APIError`, `APIResponse` | Errors + headers |
| `RetryPolicy`, `RetrySleeping`, `TaskRetrySleeper` | Retry policy |
| `APIClient`, `URLSessionAPIClient` | Async client |
| `TokenRefreshing`, `EmptyTokenRefresher`, `InMemoryDemoTokenRefresher`, `KeychainDemoTokenRefresher` | Auth hooks |
| `AccessTokenStore`, `InMemoryAccessTokenStore`, `KeychainAccessTokenStore` | Token storage |
| `APILogging`, `RedactedAPILogger` | Injectable-subsystem logging |
| `DefaultURLSession` | Shared session factory |

App-specific launch-flag wiring (`TokenRefreshingFactory` / `AppLaunchConfiguration`) stays in the host app.

## Attribution

Sources originated in `superDemoApp` tip around `6ace8aa` (2026-10). License Apache-2.0.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
