//
//  AppleIntelligence.swift
//  AproplanAI
//
//  Created by Marzena on 07/07/2026.
//

import FoundationModels

@available(iOS 26.0, *)
public final class AppleIntelligence: Sendable, AIService {
    let session: LanguageModelSession

    public init(instructions: String = "") throws {
        guard SystemLanguageModel.default.isAvailable else {
            throw AIError.notSupported("AI not available (\(SystemLanguageModel.default.availability))")
        }

        self.session = LanguageModelSession(instructions: { instructions })
    }

    public func respond(to prompt: String) async throws -> AIResponse {
        let response = try await session.respond(to: prompt)
        print("Content: \(response.content)")
        print("Raw content: \(response.rawContent)")

        for entry in response.transcriptEntries {
            print("Entry: \(entry.id): \(entry.description)")
        }

        return response.asAIResponse()
    }
}

@available(iOS 26.0, *)
extension LanguageModelSession.Response where Content == String {
    func asAIResponse() -> AIResponse {
        AIResponse(content: self.content)
    }
}
