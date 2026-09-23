//
//  Evaluator+Extensions.swift
//  AI
//
//  Created by Marzena on 09/09/2026.
//

import Evaluations

public enum CodableResult<Success: Sendable & Codable>: Sendable, Codable {
    case failure(response: String, error: String)
    case success(result: Success)
}

extension Evaluator {
    static func onSuccess<Success>(metric: Metric, evaluate: @escaping (Success, Success) -> Metric) -> Evaluator
        where Input == ModelSample<CodableResult<Success>> {

        Evaluator { input, subject in
            guard let expected = input.expected else {
                return metric.failing(rationale: "Expected value not provided")
            }

            switch expected {
            case .failure(_, let error):
                return metric.failing(rationale: "Expected failure: \(error)")
            case .success(let expected):
                switch subject.value {
                case .failure:
                    return metric.ignore(rationale: "Getting result failed")
                case .success(let value):
                    return evaluate(expected, value)
                }
            }
        }
    }

    static func onSuccess<Success, Value>(metric: Metric, compare keyPath: KeyPath<Success, Value>) -> Evaluator
        where Input == ModelSample<CodableResult<Success>>, Value: Equatable {

            onSuccess(metric: metric) { expected, received in
                if expected[keyPath: keyPath] == received[keyPath: keyPath] {
                    return metric.passing()
                } else {
                    return metric.failing(rationale: "Expected: \(expected[keyPath: keyPath]). Received: \(received[keyPath: keyPath])")
                }
            }
    }

    static func onSuccess<Success>(metric: Metric, accuracy keyPath: KeyPath<Success, String?>) -> Evaluator
        where Input == ModelSample<CodableResult<Success>> {
            onSuccess(metric: metric) { expected, received in
                metric.accuracy(between: expected[keyPath: keyPath], and: received[keyPath: keyPath])
            }
    }

    static func onSuccess<Success>(metric: Metric,
                                   keyPath: KeyPath<Success, [String]?>,
                                   score: @escaping (ArrayEvaluator) -> MetricScore) -> Evaluator
        where Input == ModelSample<CodableResult<Success>> {
            onSuccess(metric: metric) { expected, received in
                let evaluator = ArrayEvaluator(expected: expected[keyPath: keyPath] ?? [], received: received[keyPath: keyPath] ?? [])
                return metric.scoring(score(evaluator))
            }
    }

    static func onSuccess<Success>(metric: Metric,
                                   accuracy keyPath: KeyPath<Success, [String]?>) -> Evaluator
        where Input == ModelSample<CodableResult<Success>> {
            onSuccess(metric: metric, keyPath: keyPath) { evaluator in
                evaluator.accuracyScore()
            }
    }

    static func onSuccess<Success>(metric: Metric,
                                   completeness keyPath: KeyPath<Success, [String]?>) -> Evaluator
        where Input == ModelSample<CodableResult<Success>> {
            onSuccess(metric: metric, keyPath: keyPath) { evaluator in
                evaluator.completenessScore()
            }
    }

    static func onSuccess<Success>(metric: Metric,
                                   hallucinations keyPath: KeyPath<Success, [String]?>) -> Evaluator
        where Input == ModelSample<CodableResult<Success>> {
            onSuccess(metric: metric, keyPath: keyPath) { evaluator in
                evaluator.hallucinationsScore()
            }
    }
}

