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
            return L10n.tr("The request URL is invalid.", "Die Anfrage-URL ist ungültig.")
        case .invalidResponse(let statusCode):
            return L10n.tr(
                "Server returned an unexpected HTTP status code: \(statusCode).",
                "Der Server hat einen unerwarteten HTTP-Statuscode zurückgegeben: \(statusCode)."
            )
        case .apiError(let message):
            return L10n.tr(
                "Tankerkönig API error: \(message)",
                "Tankerkönig API-Fehler: \(message)"
            )
        case .decodingError(let message):
            return L10n.tr(
                "Failed to decode response: \(message)",
                "Antwort konnte nicht verarbeitet werden: \(message)"
            )
        case .unknown(let message):
            return L10n.tr(
                "Network error: \(message)",
                "Netzwerkfehler: \(message)"
            )
        }
    }
}
