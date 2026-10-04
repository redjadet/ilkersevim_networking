//
//  TokenRefreshingTests.swift
//  IlkerSevimNetworkingTests
//

import Foundation
import Testing
import IlkerSevimNetworking

@Suite("Token refreshing")
struct TokenRefreshingTests {
    @Test
    func emptyRefresherHasNoTokenAndFailsRefresh() async {
        let refresher = EmptyTokenRefresher()

        #expect(await refresher.currentAccessToken() == nil)

        await #expect(throws: APIError.unauthorizedAfterRefresh) {
            _ = try await refresher.refreshAccessToken()
        }
    }

    @Test
    func inMemoryDemoRefresherUpdatesAccessToken() async throws {
        let refresher = InMemoryDemoTokenRefresher(
            initialToken: "old",
            refreshedToken: "new"
        )

        #expect(await refresher.currentAccessToken() == "old")
        let refreshed = try await refresher.refreshAccessToken()
        #expect(refreshed == "new")
        #expect(await refresher.currentAccessToken() == "new")
        #expect(await refresher.refreshCount == 1)
    }

    @Test
    func keychainDemoRefresherPersistsThroughStore() async throws {
        let store = InMemoryAccessTokenStore()
        let refresher = KeychainDemoTokenRefresher(
            store: store,
            seedToken: "seed",
            refreshedToken: "rotated"
        )

        #expect(await refresher.currentAccessToken() == "seed")
        #expect(try store.loadAccessToken() == "seed")

        let refreshed = try await refresher.refreshAccessToken()
        #expect(refreshed == "rotated")
        #expect(try store.loadAccessToken() == "rotated")
        #expect(await refresher.refreshCount == 1)
    }

    @Test
    func keychainAccessTokenStoreRoundTrips() throws {
        let suffix = UUID().uuidString
        let store = KeychainAccessTokenStore(
            service: "com.superdemoapp.token.test.\(suffix)",
            account: "access-token-\(suffix)"
        )
        defer { try? store.clearAccessToken() }

        #expect(try store.loadAccessToken() == nil)
        try store.saveAccessToken("first")
        #expect(try store.loadAccessToken() == "first")
        try store.saveAccessToken("second")
        #expect(try store.loadAccessToken() == "second")
        try store.clearAccessToken()
        #expect(try store.loadAccessToken() == nil)
    }
}
