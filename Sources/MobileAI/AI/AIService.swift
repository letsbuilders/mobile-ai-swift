//
//  AIService.swift
//  AproplanAI
//
//  Created by Marzena on 07/07/2026.
//

public protocol AIService: Sendable {
    init(instructions: String) throws
    func respond(to prompt: String) async throws -> AIResponse
}

public struct AIResponse {
    public var content: String
}

public enum AIError: Error {
    case notSupported(_ reason: String)
}
