//
//  APIRequest.swift
//  IlkerSevimNetworking
//
//  Extracted from redjadet/super_demo_ios (superDemoApp Shared/Networking).
//

import Foundation

/// Wire method — value type used from Sendable / nonisolated networking paths.
public nonisolated enum HTTPMethod: String, Sendable {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case delete = "DELETE"
}

/// Immutable HTTP request model — must stay nonisolated under
/// `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor` so `@Sendable` transports and
/// retry policies can construct it without hopping to the main actor.
public nonisolated struct APIRequest: Sendable {
  public let url: URL
  public let method: HTTPMethod
  public let headers: [String: String]
  public let body: Data?
  public let idempotencyKey: String?

  public init(
    url: URL,
    method: HTTPMethod = .get,
    headers: [String: String] = [:],
    body: Data? = nil,
    idempotencyKey: String? = nil
  ) {
    self.url = url
    self.method = method
    self.headers = headers
    self.body = body
    self.idempotencyKey = idempotencyKey
  }

  public var isRetrySafe: Bool {
    switch self.method {
    case .get, .put, .delete:
      true
    case .post:
      self.idempotencyKey?.isEmpty == false
    }
  }

  public func urlRequest(bearerToken: String? = nil) -> URLRequest {
    var request = URLRequest(url: self.url)
    request.httpMethod = self.method.rawValue
    request.httpBody = self.body
    request.timeoutInterval = 30
    for (key, value) in self.headers {
      request.setValue(value, forHTTPHeaderField: key)
    }
    if let idempotencyKey, !idempotencyKey.isEmpty {
      request.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
    }
    if let bearerToken, !bearerToken.isEmpty {
      request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
    }
    return request
  }
}
