//
//  NetworkError.swift
//  PumpIT
//

import Foundation

public enum NetworkError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case apiError(String)
    case decodingError(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .invalidResponse(let statusCode):
            return "Server returned an unexpected HTTP status code: \(statusCode)."
        case .apiError(let message):
            return "Tankerkönig API error: \(message)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .unknown(let message):
            return "Network error: \(message)"
        }
    }
}
