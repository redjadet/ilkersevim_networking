//
//  TokenRefreshing.swift
//  IlkerSevimNetworking
//
//  Extracted from redjadet/super_demo_ios Shared/Networking.
//

import Foundation

public nonisolated protocol TokenRefreshing: Sendable {
    func currentAccessToken() async -> String?
    func refreshAccessToken() async throws -> String
}

/// Production default until a real auth/session refresher is injected.
/// Returns no access token and fails refresh so callers surface unauthorized clearly.
public nonisolated struct EmptyTokenRefresher: TokenRefreshing {
    public init() {}

    public func currentAccessToken() async -> String? {
        await Task.yield()
        return nil
    }

    public func refreshAccessToken() async throws -> String {
        await Task.yield()
        throw APIError.unauthorizedAfterRefresh
    }
}

/// Demo/in-memory auth path for unit tests and reviewer demos.
/// Prefer `KeychainDemoTokenRefresher` when proving Keychain persistence.
public actor InMemoryDemoTokenRefresher: TokenRefreshing {
    private var accessToken: String?
    private let refreshedToken: String
    public private(set) var refreshCount = 0

    public init(initialToken: String? = "demo-access", refreshedToken: String = "demo-refreshed") {
        self.accessToken = initialToken
        self.refreshedToken = refreshedToken
    }

    public func currentAccessToken() async -> String? {
        await Task.yield()
        return self.accessToken
    }

    public func refreshAccessToken() async throws -> String {
        await Task.yield()
        self.refreshCount += 1
        self.accessToken = self.refreshedToken
        return self.refreshedToken
    }
}

/// Demo refresher that persists tokens through `AccessTokenStore` (Keychain or in-memory).
/// Not real OAuth — seeds and refreshes fixed demo strings for portfolio wiring.
public actor KeychainDemoTokenRefresher: TokenRefreshing {
    private let store: any AccessTokenStore
    private let seedToken: String?
    private let refreshedToken: String
    private var didAttemptSeed = false
    public private(set) var refreshCount = 0

    public init(
        store: any AccessTokenStore,
        seedToken: String? = "demo-access",
        refreshedToken: String = "demo-refreshed"
    ) {
        self.store = store
        self.seedToken = seedToken
        self.refreshedToken = refreshedToken
    }

    public func currentAccessToken() async -> String? {
        await Task.yield()
        if let existing = try? self.store.loadAccessToken() {
            return existing
        }
        guard let seed = self.seedToken, !self.didAttemptSeed else {
            return nil
        }
        self.didAttemptSeed = true
        do {
            try self.store.saveAccessToken(seed)
            return seed
        } catch {
            return nil
        }
    }

    public func refreshAccessToken() async throws -> String {
        await Task.yield()
        do {
            try self.store.saveAccessToken(self.refreshedToken)
            self.refreshCount += 1
            return self.refreshedToken
        } catch {
            throw APIError.unauthorizedAfterRefresh
        }
    }
}
