# Cancellation

Sources of truth: `Sources/IlkerSevimNetworking/URLSessionAPIClient.swift`,
`RetryPolicy.swift`, `APIError.swift`, and the cancellation paths in
`Tests/IlkerSevimNetworkingTests/URLSessionAPIClientTests.swift`.

## How a request is cancelled

`URLSessionAPIClient` does **not** expose an explicit cancel handle, token, or
`cancel()` method. Cancellation is cooperative Swift concurrency:

1. **Loop-entry check** — each attempt in `send(_:)` begins with
   `try Task.checkCancellation()` (`URLSessionAPIClient.send`).
2. **URLSession async I/O** — `perform(_:bearerToken:)` calls
   `session.data(for:)`. When the enclosing `Task` is cancelled, Foundation
   surfaces that as either `CancellationError` or `URLError(.cancelled)`.
3. **Retry sleep** — `waitBeforeRetry` uses the injected `RetrySleeping`
   (default `TaskRetrySleeper`, which calls `Task.sleep(nanoseconds:)`).
   Cancelling during backoff throws `CancellationError` from sleep into the
   same `send` catch paths.

There is no `withTaskCancellationHandler`, no `URLSessionTask` retain/cancel
API, and no package-level cancel registry.

## What the caller receives

Cancellation is always rethrown as **`CancellationError`**, not as
`APIError`:

| Incoming failure | What `send` throws |
| --- | --- |
| `CancellationError` | `CancellationError()` (rethrown; not mapped) |
| `URLError` with `code == .cancelled` | `CancellationError()` |
| Other `URLError` | `APIError.transport(code)` (may retry) |
| Domain / HTTP failures | `APIError` cases (may retry) |

Relevant catch blocks in `URLSessionAPIClient.send`:

```swift
} catch is CancellationError {
    // Preserve cooperative cancel — do not map to a domain failure.
    throw CancellationError()
} catch let error as APIError {
    // … retry or rethrow …
} catch let error as URLError where error.code == .cancelled {
    throw CancellationError()
} catch let error as URLError {
    // … map to APIError.transport and maybe retry …
}
```

`APIError.cancelled` exists on the enum (`APIError.swift`) and has a localized
description, but **`URLSessionAPIClient` never throws it**. Callers that want
to distinguish cancel from failure should catch `CancellationError`, not
`APIError.cancelled`.

## Distinguishing cancel from failures

| Kind | Type to catch / compare | Retryable? |
| --- | --- | --- |
| Cooperative / session cancel | `CancellationError` | No — catch runs before retry |
| Transport failure | `APIError.transport(URLError.Code)` | Only for codes in `RetryPolicy.retryableTransportCodes` |
| HTTP failure | `APIError.httpStatus(Int)` | Only for 429 / 500 / 502 / 503 / 504 when `request.isRetrySafe` |
| Auth exhausted | `APIError.unauthorizedAfterRefresh` | No (`RetryPolicy.shouldRetry` returns `false`) |

`RetryPolicy.shouldRetry` explicitly returns `false` for
`.cancelled` (and for `.invalidResponse`, `.unauthorizedAfterRefresh`,
`.decodingFailed`). Even if something threw `APIError.cancelled`, the policy
would not retry it. In practice the live client path never produces that case.

## Retries and cancellation

- Cancelled attempts **do not enter** the `APIError` / non-cancel `URLError`
  retry branches; the dedicated cancel catches throw immediately.
- After a successful retry decision, `waitBeforeRetry` sleeps; if that sleep
  is cancelled, the next catch sees `CancellationError` and surfaces cancel
  rather than continuing the loop.
- `Task.checkCancellation()` at the top of each attempt stops a cancelled
  task from starting another HTTP round trip.

## Tests

Covered by the private helper `preservesCancellationError()` inside
`URLSessionAPIClientTests.exercisesRetryAuthAndFailureMapping`
(`Tests/IlkerSevimNetworkingTests/URLSessionAPIClientTests.swift`):

1. Cancel the `Task` wrapping `client.send` → expects `CancellationError`.
2. Stub `URLError(.cancelled)` from the protocol → expects
   `CancellationError` (not `APIError.transport(.cancelled)`).

### Gaps

- No test that cancellation **during** `RetrySleeping.sleep` aborts the retry
  loop with `CancellationError`.
- No assertion that `APIError.cancelled` is unused by the client.
- No public cancel-handle API to document or test.
