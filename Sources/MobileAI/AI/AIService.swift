//
//  AIService.swift
//  AproplanAI
//
//  Created by Marzena on 07/07/2026.
//

import FoundationModels
import SwiftUI

public nonisolated protocol AIService: Sendable {
    func downloadModel(_ progressBlock: @escaping (Progress) -> Void) async throws

    func startSession(instructions: String, maxTokens: Int?) throws -> AISession

    @available(macOS 26.0, *)
    @available(iOS 26.0, *)
    func startSession(instructions: String, tools: [any Tool]?, maxTokens: Int?) throws -> AISession
}

public nonisolated protocol AISession: Sendable {
    func respond(to prompt: String) async throws -> AIResponse
    @available(macOS 26.0, *)
    @available(iOS 26.0, *)
    func generate<Entity: Generable>(from prompt: String, type: Entity.Type) async throws -> Entity
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
