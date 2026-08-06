//
//  AppleIntelligence.swift
//  AproplanAI
//
//  Created by Marzena on 07/07/2026.
//

import FoundationModels
import SwiftUI

@available(macOS 26.0, *)
@available(iOS 26.0, *)
public final class AppleIntelligence: Sendable, AIService, Loggable {
    public init() throws {
        guard SystemLanguageModel.default.isAvailable else {
            throw AIError.notSupported("AI not available (\(SystemLanguageModel.default.availability))")
        }
    }

    public func downloadModel(_ progressBlock: @escaping (Progress) -> Void) async throws {
        let progress = Progress(totalUnitCount: 100)
        progress.completedUnitCount = 100
        progressBlock(progress)
    }

    public func startSession(instructions: String) throws -> AISession {
        Session(session: LanguageModelSession(instructions: { instructions }))
    }
}

@available(macOS 26.0, *)
@available(iOS 26.0, *)
extension LanguageModelSession.Response where Content == String {
    func asAIResponse() -> AIResponse {
        AIResponse(content: self.content)
    }
}

@available(macOS 26.0, *)
@available(iOS 26.0, *)
private struct Session: AISession, Loggable  {
    var session: LanguageModelSession

    public func respond(to prompt: String) async throws -> AIResponse {
        info("Prompt: \(prompt)")
        let response = try await session.respond(to: prompt)

        for entry in response.transcriptEntries {
            info("AI: \(entry.id)\n\(entry.description)")
        }

        return response.asAIResponse()
    }
}
