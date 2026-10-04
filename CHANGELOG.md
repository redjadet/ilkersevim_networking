# Changelog

## 1.0.0

Initial public release.

- `URLSessionAPIClient` with retry, `Retry-After`, 401 refresh-once, cancellation honesty
- `APIRequest` idempotency-key / retry-safe POST rules
- `RetryPolicy` exponential backoff + jitter with saturating math
- Token store / refresher protocols + in-memory and Keychain demos
- `RedactedAPILogger` with injectable subsystem/category
- `DefaultURLSession` shared session factory
