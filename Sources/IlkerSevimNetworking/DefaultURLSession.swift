//
//  DefaultURLSession.swift
//  IlkerSevimNetworking
//
//  Extracted from redjadet/super_demo_ios Shared/Networking (was AppURLSession).
//

import Foundation

public enum DefaultURLSession {
  /// One process-wide session; avoids leaking `URLSession` instances from repeated `makeDefault()` calls.
  private static let sharedSession: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 30
    configuration.timeoutIntervalForResource = 60
    configuration.waitsForConnectivity = true
    return URLSession(configuration: configuration)
  }()

  /// Shared defaults for host-issued HTTP (matches `APIRequest` request timeout).
  public static func makeDefault() -> URLSession {
    self.sharedSession
  }
}
