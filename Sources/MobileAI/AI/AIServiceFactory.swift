//
//  AIServiceFactory.swift
//  MobileAI
//
//  Created by Marzena on 06/08/2026.
//

import MLXLLM

public enum AIModelKind: String, CaseIterable, Identifiable {
    case appleIntelligence = "Apple Intelligence"
    case gemma = "Gemma 4 (4B) - 5.18GB"
    case llama = "Llama 3.2 (3B) - 1.82GB"
    case phi = "Phi 3.5 (3.8B) - 2.15GB"
    case qwen = "Qwen 3 (4B) - 2.28GB"
    case smollm = "SmolLM 3 (3B) - 1.75GB"
    case deepSeek = "DeepSeek R1 (7B)"
    case openELM = "OpenELM"

    public var id: String { rawValue }
}

public class AIServiceFactory {
    public static func make(kind: AIModelKind) throws -> AIService {
        switch kind {
        case .appleIntelligence:
            if #available(iOS 26.0, *) {
                try AppleIntelligence()
            } else {
                throw AIError.notSupported("Available only for iOS 26.0+")
            }
        case .gemma: MLXManager(config: LLMRegistry.gemma4_e4b_it_4bit)
        case .phi: MLXManager(config: LLMRegistry.phi3_5_4bit)
        case .llama: MLXManager(config: LLMRegistry.llama3_2_3B_4bit)
        case .qwen: MLXManager(config: LLMRegistry.qwen3_4b_4bit)
        case .smollm: MLXManager(config: LLMRegistry.smollm3_3b_4bit)
        case .deepSeek: MLXManager(config: LLMRegistry.deepSeekR1_7B_4bit)
        case .openELM: MLXManager(config: LLMRegistry.openelm270m4bit)
        }
    }
}
