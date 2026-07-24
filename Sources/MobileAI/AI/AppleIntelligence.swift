//
//  AppleIntelligence.swift
//  AproplanAI
//
//  Created by Marzena on 07/07/2026.
//

import FoundationModels

@available(macOS 26.0, *)
@available(iOS 26.0, *)
public final class AppleIntelligence: Sendable, AIService, Loggable {
    let session: LanguageModelSession

    public init(instructions: String = "") throws {
        guard SystemLanguageModel.default.isAvailable else {
            throw AIError.notSupported("AI not available (\(SystemLanguageModel.default.availability))")
        }

        self.session = LanguageModelSession(instructions: { instructions })
    }

    public func respond(to prompt: String) async throws -> AIResponse {
        info("Prompt: \(prompt)")
        let response = try await session.respond(to: prompt)

        for entry in response.transcriptEntries {
            info("AI: \(entry.id)\n\(entry.description)")
        }

        return response.asAIResponse()
    }
}

@available(macOS 26.0, *)
@available(iOS 26.0, *)
extension LanguageModelSession.Response where Content == String {
    func asAIResponse() -> AIResponse {
        AIResponse(content: self.content)
    }
}
