//
//  AIService.swift
//  AproplanAI
//
//  Created by Marzena on 07/07/2026.
//

import SwiftUI

public nonisolated protocol AIService: Sendable {
    func downloadModel(_ progressBlock: @escaping (Progress) -> Void) async throws
    func startSession(instructions: String) throws -> AISession
}

public nonisolated protocol AISession: Sendable {
    func respond(to prompt: String) async throws -> AIResponse
}

public struct AIResponse {
    public var content: String
}

public enum AIError: LocalizedError {
    case notSupported(_ reason: String)

    public var errorDescription: String? {
        return String(reflecting: self)
    }
}
