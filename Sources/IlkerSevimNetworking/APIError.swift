//
//  APIError.swift
//  IlkerSevimNetworking
//
//  Extracted from redjadet/super_demo_ios (superDemoApp Shared/Networking).
//

import Foundation

public nonisolated enum APIError: Error, Equatable, LocalizedError, Sendable {
  case invalidResponse
  case transport(URLError.Code)
  case httpStatus(Int)
  case unauthorizedAfterRefresh
  case decodingFailed
  case cancelled

  public var errorDescription: String? {
    switch self {
    case .invalidResponse:
      "The server response was invalid."
    case let .transport(code):
      "The network request failed: \(code)."
    case let .httpStatus(status):
      "The server returned HTTP \(status)."
    case .unauthorizedAfterRefresh:
      "The session could not be refreshed."
    case .decodingFailed:
      "The response could not be decoded."
    case .cancelled:
      "The request was cancelled."
    }
  }
}

public nonisolated struct APIResponse: Sendable {
  public let data: Data
  public let statusCode: Int
  public let headers: [String: String]

  public init(data: Data, statusCode: Int, headers: [String: String]) {
    self.data = data
    self.statusCode = statusCode
    self.headers = headers
  }

  public func headerValue(for name: String) -> String? {
    let normalized = name.lowercased()
    return self.headers.first { $0.key.lowercased() == normalized }?.value
  }
}
