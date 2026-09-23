//
//  MLXManager.swift
//  MobileAI
//
//  Created by Marzena on 06/08/2026.
//

import Foundation
import Hub
import MLX
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import HuggingFace
import Tokenizers

public class MLXManager: Loggable, AIService {
    public static var shared = MLXManager(config: LLMRegistry.qwen3_4b_4bit)
    var config: ModelConfiguration
    var model: ModelContainer!
    var session: ChatSession!

    public init(config: ModelConfiguration) {
        self.config = config
    }

    deinit {
        Log.info(Self.self, "Deinit")
    }

    public func downloadModel(_ progressBlock: @escaping (Progress) -> Void) async throws {
        self.model = try await loadModelContainer(
            from: #hubDownloader(),
            using: #huggingFaceTokenizerLoader(),
            configuration: config,
            progressHandler: { progress in
                Log.info(Self.self, "Progress \(progress.completedUnitCount)/\(progress.totalUnitCount) \(progress.fractionCompleted)")
                progressBlock(progress)
            })

        let progress = Progress(totalUnitCount: 1)
        progress.completedUnitCount = 1
        progressBlock(progress)
    }

    public func startSession(instructions: String, maxTokens: Int?) throws -> AISession {
        Log.info(Self.self, "Starting session... Instructions: \(instructions.count). Max tokens: \(maxTokens ?? -1)")

        let parameters = GenerateParameters(
            maxTokens: maxTokens,
            temperature: 0.6
        )

        return Session(session: ChatSession(model, instructions: instructions, generateParameters: parameters))
    }
}

private struct Session: AISession {
    var session: ChatSession

    init(session: ChatSession) {
        self.session = session
        print("Parameters \(session.generateParameters.temperature) \(session.generateParameters.maxTokens)")
    }

    public func respond(to prompt: String) async throws -> AIResponse {
        let response = try await self.session.respond(to: prompt)
        return AIResponse(content: response)
    }
}
