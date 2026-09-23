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

struct AIPointTests {
    static let samples = AITestData().loadSamples(prefix: "point_", type: AIPoint.self)

    static func runPointCreationTest(for evaluation: PointEvaluation) async throws {
        let result = EvaluationContext.current.result
        #expect(result.aggregateValue(.mean(of: evaluation.json)) == 1.0)
    }

    @Suite struct SmalL {
        static let evaluation = PointEvaluation(kind: .mlx(LLMRegistry.smollm3_3b_4bit), samples: AIPointTests.samples)

        @Test(.evaluates(evaluation))
        func testPointCreation() async throws {
            try await AIPointTests.runPointCreationTest(for: Self.evaluation)
        }
    }

    @Suite struct Qwen {
        static let evaluation = PointEvaluation(kind: .mlx(LLMRegistry.qwen3_4b_4bit), samples: AIPointTests.samples)

        @Test(.evaluates(evaluation))
        func testPointCreation() async throws {
            try await AIPointTests.runPointCreationTest(for: Self.evaluation)
        }
    }

    @Suite struct AppleIntelligence {
        static let evaluation = PointEvaluation(kind: .appleIntelligence, samples: AIPointTests.samples)

        @Test(.evaluates(evaluation))
        func testPointCreation() async throws {
            try await AIPointTests.runPointCreationTest(for: Self.evaluation)
        }
    }

    @Suite struct Llama {
        static let evaluation = PointEvaluation(kind: .mlx(LLMRegistry.llama3_2_3B_4bit), samples: AIPointTests.samples)

        @Test(.evaluates(evaluation))
        func testPointCreation() async throws {
            try await AIPointTests.runPointCreationTest(for: Self.evaluation)
        }
    }

    @Suite struct Phi {
        static let evaluation = PointEvaluation(kind: .mlx(LLMRegistry.phi3_5_4bit), samples: AIPointTests.samples)

        @Test(.evaluates(evaluation))
        func testPointCreation() async throws {
            try await AIPointTests.runPointCreationTest(for: Self.evaluation)
        }
    }
}
