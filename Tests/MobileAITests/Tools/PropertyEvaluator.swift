//
//  PropertyEvaluator.swift
//  AI
//
//  Created by Marzena on 16/09/2026.
//

import Evaluations

public nonisolated struct PropertyEvaluator<Input: Sendable & Codable>: Sendable {
    public let name: String
    public let metricName: String
    public var fullMetricName: String {
        "\(name) \(metricName)"
    }
    public let metricScoreFunction: MetricScoreFunction<Input>

    public init<Output: Sendable & Codable>(name: String,
                                            metricName: String,
                                            keyPath: KeyPath<Input, Output>,
                                            metricScoreFunction: @escaping MetricScoreFunction<Output>) {
        self.name = name
        self.metricName = metricName
        self.metricScoreFunction = Self.convert(keyPath: keyPath, metricScore: metricScoreFunction)
    }

    func evaluator() -> Evaluator<ModelSample<CodableResult<Input>>> {
        let metric = Metric(fullMetricName)
        return .onSuccess(metric: metric) { expected, received in
            return metric.scoring(metricScoreFunction(expected, received))
        }
    }

    private static func convert<Output: Sendable & Codable>(keyPath: KeyPath<Input, Output>,
                                                            metricScore: @escaping MetricScoreFunction<Output>) -> @Sendable (Input, Input) -> MetricScore {
        { expected, received in
            metricScore(expected[keyPath: keyPath], received[keyPath: keyPath])
        }
    }
}

public extension PropertyEvaluator {
    static func accuracy(name: String, keyPath: KeyPath<Input, String?>) -> PropertyEvaluator<Input> {
        PropertyEvaluator(name: name,
                          metricName: "Accuracy",
                          keyPath: keyPath,
                          metricScoreFunction: MetricScore.accuracy)
    }

    static func equality(name: String, keyPath: KeyPath<Input, String?>) -> PropertyEvaluator<Input> {
        PropertyEvaluator(name: name,
                          metricName: "Equality",
                          keyPath: keyPath,
                          metricScoreFunction: MetricScore.equality)
    }

    static func halucinations(name: String, keyPath: KeyPath<Input, String?>) -> PropertyEvaluator<Input> {
        PropertyEvaluator(name: name,
                          metricName: "Halucinations",
                          keyPath: keyPath,
                          metricScoreFunction: MetricScore.halucinations)
    }

    static func equality(name: String, keyPath: KeyPath<Input, Bool?>) -> PropertyEvaluator<Input> {
        PropertyEvaluator(name: name,
                          metricName: "Equality",
                          keyPath: keyPath,
                          metricScoreFunction: MetricScore.equality)
    }

    static func equality(name: String, keyPath: KeyPath<Input, [String]?>) -> PropertyEvaluator<Input> {
        PropertyEvaluator(name: name,
                          metricName: "Equality",
                          keyPath: keyPath,
                          metricScoreFunction: MetricScore.arrayEquality)
    }

    static func completeness(name: String, keyPath: KeyPath<Input, [String]?>) -> PropertyEvaluator<Input> {
        PropertyEvaluator(name: name,
                          metricName: "Completeness",
                          keyPath: keyPath) { expected, received in
            ArrayEvaluator(expected: expected ?? [], received: received ?? [])
                .completenessScore()
        }
    }

    static func accuracy(name: String, keyPath: KeyPath<Input, [String]?>) -> PropertyEvaluator<Input> {
        PropertyEvaluator(name: name,
                          metricName: "Accuracy",
                          keyPath: keyPath) { expected, received in
            ArrayEvaluator(expected: expected ?? [], received: received ?? [])
                .accuracyScore()
        }
    }

    static func hallucinations(name: String, keyPath: KeyPath<Input, [String]?>) -> PropertyEvaluator<Input> {
        PropertyEvaluator(name: name,
                          metricName: "Hallucinations",
                          keyPath: keyPath) { expected, received in
            ArrayEvaluator(expected: expected ?? [], received: received ?? [])
                .hallucinationsScore()
        }
    }
}
