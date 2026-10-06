# IlkerSevimNetworking

[![CI](https://github.com/redjadet/ilkersevim_networking/actions/workflows/ci.yml/badge.svg)](https://github.com/redjadet/ilkersevim_networking/actions/workflows/ci.yml)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](Package.swift)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2017%20%7C%20macOS%2014%20%7C%20watchOS%2010-lightgrey)](Package.swift)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

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

### Swift Package Manager

Swift Package Manager is the supported installation method:

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

The pod publishes to CocoaPods trunk via the
[`publish-cocoapods`](.github/workflows/publish-cocoapods.yml) workflow
(semver tags matching `X.Y.Z`, or manual `workflow_dispatch`).

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

The networking sources were extracted from the `superDemoApp` shared networking
layer in [`redjadet/super_demo_ios`](https://github.com/redjadet/super_demo_ios)
at commit [`6ace8aa`](https://github.com/redjadet/super_demo_ios/commit/6ace8aa)
(October 2026).

## License

Apache License 2.0 — see [LICENSE](LICENSE).
