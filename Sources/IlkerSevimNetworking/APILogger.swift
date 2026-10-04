//
//  APILogger.swift
//  IlkerSevimNetworking
//
//  Extracted from redjadet/super_demo_ios Shared/Networking.
//

import Foundation
import os

public protocol APILogging: Sendable {
  func requestStarted(_ request: APIRequest, attempt: Int)
  func requestFinished(url: URL, statusCode: Int, attempt: Int)
  func requestFailed(url: URL, error: APIError, attempt: Int)
}

/// Host/status/attempt logger — never logs Authorization headers or bodies.
public struct RedactedAPILogger: APILogging {
  private let logger: Logger

  public init(
    subsystem: String = "com.ilkersevim.networking",
    category: String = "networking"
  ) {
    self.logger = Logger(subsystem: subsystem, category: category)
  }

  public func requestStarted(_ request: APIRequest, attempt: Int) {
    self.logger
      .info(
        "request started method=\(request.method.rawValue, privacy: .public) host=\(request.url.host() ?? "unknown", privacy: .public) attempt=\(attempt, privacy: .public)"
      )
  }

  public func requestFinished(url: URL, statusCode: Int, attempt: Int) {
    self.logger
      .info(
        "request finished host=\(url.host() ?? "unknown", privacy: .public) status=\(statusCode, privacy: .public) attempt=\(attempt, privacy: .public)"
      )
  }

  public func requestFailed(url: URL, error: APIError, attempt: Int) {
    self.logger
      .error(
        "request failed host=\(url.host() ?? "unknown", privacy: .public) error=\(String(describing: error), privacy: .public) attempt=\(attempt, privacy: .public)"
      )
  }
}
