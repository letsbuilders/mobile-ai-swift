//
//  MLXManager.swift
//  MobileAI
//
//  Created by Marzena on 06/08/2026.
//

import Foundation
import FoundationModels
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

    @available(macOS 26.0, *)
    @available(iOS 26.0, *)
    public func startSession(instructions: String,
                             tools: [any FoundationModels.Tool]?,
                             maxTokens: Int?) throws -> AISession {
        Log.info(Self.self, "Starting session... Instructions: \(instructions.count). Max tokens: \(maxTokens ?? -1)")

        let parameters = GenerateParameters(
            maxTokens: maxTokens,
            temperature: 0.6
        )
        
        let tools = (tools ?? []).map { $0.mlxToolSchema }
        return Session(session: ChatSession(model,
                                            instructions: instructions,
                                            generateParameters: parameters,
                                            tools: tools))
    }

    public func startSession(instructions: String, maxTokens: Int?) throws -> any AISession {
        Log.info(Self.self, "Starting session... Instructions: \(instructions.count). Max tokens: \(maxTokens ?? -1)")

        let parameters = GenerateParameters(
            maxTokens: maxTokens,
            temperature: 0.6
        )

        return Session(session: ChatSession(model,
                                            instructions: instructions,
                                            generateParameters: parameters))
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

    @available(macOS 26.0, *)
    @available(iOS 26.0, *)
    func generate<Entity>(from prompt: String, type: Entity.Type) async throws -> Entity where Entity : Generable {
        preconditionFailure("Not supported")
    }
}

@available(macOS 26.0, *)
@available(iOS 26.0, *)
extension FoundationModels.Tool {
    /// Converts a FoundationModels Tool into MLX's Tool dictionary schema
    var mlxToolSchema: [String: Any] {
        return [
            "type": "function",
            "function": [
                "name": self.name,
                "description": self.description,
                "parameters": [
                    "type": "object",
                    "properties": self.extractProperties(),
                    "required": self.extractRequired()
                ]
            ]
        ]
    }

    private func extractProperties() -> [String: [String: String]] {
        var properties: [String: [String: String]] = [:]
        let mirror = Mirror(reflecting: Self.Arguments.self)

        for child in mirror.children {
            if let label = child.label {
                // Strip property wrapper prefix if present
                let key = label.hasPrefix("_") ? String(label.dropFirst()) : label
                properties[key] = [
                    "type": "string",
                    "description": "Parameter \(key)"
                ]
            }
        }
        return properties
    }

    private func extractRequired() -> [String] {
        let mirror = Mirror(reflecting: Self.Arguments.self)
        return mirror.children.compactMap { child in
            guard let label = child.label else { return nil }
            return label.hasPrefix("_") ? String(label.dropFirst()) : label
        }
    }
}
