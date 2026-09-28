//
//  AIParamTests.swift
//  AI
//
//  Created by Marzena on 27/08/2026.
//

import Foundation
import Testing
import Evaluations
import MLXLLM
@testable import MobileAI

import Testing
import Evaluations

class AITestDataClass {}

@Suite struct CreatePointTests {
    static let samples = AITestData().loadSamples(prefix: "point_", type: AIPoint.self)

    fileprivate static let appleIntelligence = AppleIntelligence(samples: samples)
    fileprivate static let gemma = Gemma(samples: samples)
    fileprivate static let phi = Phi(samples: samples)
    fileprivate static let llama = Llama(samples: samples)
    fileprivate static let qwen = Qwen(samples: samples)
    fileprivate static let smolLM = SmolLM(samples: samples)

    @Test(.evaluates(appleIntelligence))
    func testAppleIntelligence() async throws {
        try await runPointCreationTest(for: Self.appleIntelligence)
    }

    @Test(.evaluates(gemma))
    func testGemma() async throws {
        try await runPointCreationTest(for: Self.gemma)
    }

    @Test(.evaluates(llama))
    func testLlama() async throws {
        try await runPointCreationTest(for: Self.llama)
    }

    @Test(.evaluates(phi))
    func testPhi() async throws {
        try await runPointCreationTest(for: Self.phi)
    }

    @Test(.evaluates(qwen))
    func testQwen() async throws {
        try await runPointCreationTest(for: Self.qwen)
    }

    /*
    // This model is problematic because sometimes it can generate a single response in 12 min
    @Test(.evaluates(smolLM))
    func testSmolLM() async throws {
        try await runPointCreationTest(for: Self.smolLM)
    }
     */
}

fileprivate extension CreatePointTests {
    func runPointCreationTest<E: CreatePointEvaluation>(for evaluation: E) async throws {
        let result = EvaluationContext.current.result
        #expect(result.aggregateValue(.mean(of: evaluation.json)) == 1.0)
    }
}

// MARK: Model Evaluators

fileprivate struct AppleIntelligence: CreatePointEvaluation {
    let kind: AIModelKind = .appleIntelligence
    let dataset: ArrayLoader<ModelSample<CodableResult<AIPoint>>>

    init(samples: [ModelSample<CodableResult<AIPoint>>]) {
        self.dataset = ArrayLoader(samples: samples)
    }
}

fileprivate struct Gemma: CreatePointEvaluation {
    let kind: AIModelKind = .mlx(LLMRegistry.gemma4_e4b_it_4bit)
    let dataset: ArrayLoader<ModelSample<CodableResult<AIPoint>>>

    init(samples: [ModelSample<CodableResult<AIPoint>>]) {
        self.dataset = ArrayLoader(samples: samples)
    }
}

fileprivate struct Llama: CreatePointEvaluation {
    let kind: AIModelKind = .mlx(LLMRegistry.llama3_2_3B_4bit)
    let dataset: ArrayLoader<ModelSample<CodableResult<AIPoint>>>

    init(samples: [ModelSample<CodableResult<AIPoint>>]) {
        self.dataset = ArrayLoader(samples: samples)
    }
}

fileprivate struct Phi: CreatePointEvaluation {
    let kind: AIModelKind = .mlx(LLMRegistry.phi3_5_4bit)
    let dataset: ArrayLoader<ModelSample<CodableResult<AIPoint>>>

    init(samples: [ModelSample<CodableResult<AIPoint>>]) {
        self.dataset = ArrayLoader(samples: samples)
    }
}

fileprivate struct Qwen: CreatePointEvaluation {
    let kind: AIModelKind = .mlx(LLMRegistry.qwen3_4b_4bit)
    let dataset: ArrayLoader<ModelSample<CodableResult<AIPoint>>>

    init(samples: [ModelSample<CodableResult<AIPoint>>]) {
        self.dataset = ArrayLoader(samples: samples)
    }
}

fileprivate struct SmolLM: CreatePointEvaluation {
    let kind: AIModelKind = .mlx(LLMRegistry.smollm3_3b_4bit)
    let dataset: ArrayLoader<ModelSample<CodableResult<AIPoint>>>

    init(samples: [ModelSample<CodableResult<AIPoint>>]) {
        self.dataset = ArrayLoader(samples: samples)
    }
}
