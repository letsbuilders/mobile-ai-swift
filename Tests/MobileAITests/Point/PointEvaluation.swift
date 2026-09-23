//
//  PointCreation.swift
//  AI
//
//  Created by Marzena on 10/09/2026.
//

import Evaluations
import Foundation
import FoundationModels
import NaturalLanguage
import MLX
import MLXLLM
import Testing
@testable import MobileAI

struct PointEvaluation: Evaluation {
    let json = Metric("Json")
    let propertiesAccuracy = Metric("Properties Accuracy")
    let runningTime = Metric("Time")

    let dataset: ArrayLoader<ModelSample<CodableResult<AIPoint>>>
    let kind: AIModelKind
    let maxTokens: Int?

    init(kind: AIModelKind, samples: [ModelSample<CodableResult<AIPoint>>], maxTokens: Int? = nil) {
        print("========== \(kind.name)")
        self.kind = kind
        self.maxTokens = maxTokens
        self.dataset = ArrayLoader(samples: samples)
    }

    subscript(kind: AIPointProperty) -> PropertyEvaluator<AIPoint> {
        kind.evaluator
    }

    var usersEvaluators: PropertyArrayEvaluators<AIPoint> {
        PropertyArrayEvaluators(name: "Users", keyPath: \.usersInCharge)
    }

    var customFieldsEvaluators: PropertyArrayEvaluators<AIPoint> {
        PropertyArrayEvaluators(name: "Custom Fields", keyPath: \.customFields)
    }

    var evaluators: Evaluators {
        Evaluator { input, subject in
            switch subject.value {
            case .failure(_, let error):
                return json.failing(rationale: error)
            case .success:
                return json.passing()
            }
        }

        Evaluator<ModelSample<CodableResult<AIPoint>>>.onSuccess(metric: runningTime) { expected, received in
            runningTime.scoring(received.runningTime ?? 0.0)
        }

        self[.subject].evaluator()

        self[.status].evaluator()
        self[.dueDate].evaluator()
        self[.isImportant].evaluator()

        self[.workspace].evaluator()
        self[.category].evaluator()
        self[.location].evaluator()
        self[.room].evaluator()
        self[.customFields].evaluator()

        usersEvaluators.accuracy.evaluator()
        usersEvaluators.completeness.evaluator()
        usersEvaluators.halucinations.evaluator()
        usersEvaluators.equality.evaluator()

        customFieldsEvaluators.accuracy.evaluator()
        customFieldsEvaluators.completeness.evaluator()
        customFieldsEvaluators.halucinations.evaluator()
        customFieldsEvaluators.equality.evaluator()

        AIPointProperty.allProperties.map { $0.evaluator }.combinedMetric(metric: propertiesAccuracy)
    }

    func aggregateMetrics(using aggregator: inout MetricsAggregator) {
        aggregator.group("Accuracy") { group in
            group.computeMean(of: json)
            group.computeMean(of: runningTime)
            group.computeMean(of: propertiesAccuracy)
            group.computeMean(of: Metric(AIPointProperty.subject.evaluator.fullMetricName))
        }

        aggregator.group("Properties") { group in
            group.computeMean(of: Metric(AIPointProperty.status.evaluator.fullMetricName))
            group.computeMean(of: Metric(AIPointProperty.dueDate.evaluator.fullMetricName))
            group.computeMean(of: Metric(AIPointProperty.isImportant.evaluator.fullMetricName))
            group.computeMean(of: Metric(AIPointProperty.workspace.evaluator.fullMetricName))
            group.computeMean(of: Metric(AIPointProperty.category.evaluator.fullMetricName))
            group.computeMean(of: Metric(AIPointProperty.location.evaluator.fullMetricName))
            group.computeMean(of: Metric(AIPointProperty.room.evaluator.fullMetricName))
        }

        aggregator.group(evaluators: usersEvaluators)
        aggregator.group(evaluators: customFieldsEvaluators)
    }

    func subject(from sample: ModelSample<CodableResult<AIPoint>>) async throws -> ModelSubject<CodableResult<AIPoint>> {
        let start = Date.now
        defer {
            let end = Date.now
            print("Finished test (\(kind.name)) in \(end.timeIntervalSince1970 - start.timeIntervalSince1970) sec")
        }

        // #if os(iOS)
        Memory.clearCache()
        Memory.memoryLimit = 6144 * 1024 * 1024
        Memory.cacheLimit = 6144 * 1024 * 1024
        // #endif

        do {
            let service = try AIServiceFactory.make(kind: kind)
            try await service.downloadModel({ _ in })
            let session = try service.startSession(instructions: sample.instructionsDescription ?? "", maxTokens: maxTokens)
            let sessionResult = try await session.respond(to: sample.promptDescription)
            print("Response: \(sessionResult.content)")
            let result = sessionResult.content.fixJson()
            print("Parse: \(result)")
            do {
                let jsonDecoder = JSONDecoder()
                let data = result.data(using: .utf8)!
                var point = try jsonDecoder.decode(AIPoint.self, from: data)
                point.runningTime = Date.now.timeIntervalSince1970 - start.timeIntervalSince1970
                return ModelSubject(value: .success(result: point))
            } catch {
                print("Failed parsing json: \(sessionResult.content)")
                print("Error: \(error)")
                return ModelSubject(value: .failure(response: sessionResult.content, error: "Invalid json: \(result). Error: \(error)"))
            }
        } catch {
            print("AI error: \(error.localizedDescription)")
            return ModelSubject(value: .failure(response: "", error: error.localizedDescription))
        }
    }
}
/*
public extension Evaluator {
    static func accuracy<Success>(name: String, _ evaluators: [PropertyEvaluator<Success>]) -> Evaluator<Input> where Input == ModelSample<CodableResult<Success>> {
        evaluators.map { $0.accuracy }.combinedMetric(name: name, evaluators, metricMapper: { $0.accuracy })
    }
}
*/

public extension Array {
    func combinedMetric<Success>(metric: Metric) -> Evaluator<ModelSample<CodableResult<Success>>> where Element == PropertyEvaluator<Success> {
        combinedMetric(metric: metric, metricMapper: { $0.metricScoreFunction })
    }

    func combinedMetric<Success>(metric: Metric,
                                 metricMapper: @escaping (PropertyEvaluator<Success>) -> MetricScoreFunction<Success>) -> Evaluator<ModelSample<CodableResult<Success>>>
        where Element == PropertyEvaluator<Success> {
        return .onSuccess(metric: metric) { expected, received in
            let score = self
                .map { metricMapper($0)(expected, received) }
                .mean()

            return metric.scoring(score)
        }
    }
}

extension String {
    func extractJson() -> String {
        let pattern = #"```(?:json)?\s*([\s\S]*?)\s*```"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)),
              let range = Range(match.range(at: 1), in: self) else {
            return self.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return String(self[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func removeThink() -> String {
        let regex = #/<think>[\s\S]*?</think>/#
        return self.replacing(regex, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func extractPureJson() -> String? {
        guard let startIndex = self.firstIndex(of: "{") else { return nil }

        var depth = 0
        var endIndex: String.Index?
        var inString = false
        var isEscaped = false

        for index in self.indices[startIndex...] {
            let char = self[index]

            // Handle escape characters inside strings
            if isEscaped {
                isEscaped = false
                continue
            }
            if char == "\\" && inString {
                isEscaped = true
                continue
            }

            // Toggle string state to ignore braces inside JSON values
            if char == "\"" {
                inString.toggle()
                continue
            }

            // Count depth outside of strings
            if !inString {
                if char == "{" {
                    depth += 1
                } else if char == "}" {
                    depth -= 1
                    if depth == 0 {
                        endIndex = index
                        break
                    }
                }
            }
        }

        guard let validEndIndex = endIndex else { return nil }
        return String(self[startIndex...validEndIndex])
    }

    func fixJson() -> String {
        removeThink()
            .extractJson()
            .extractPureJson() ?? ""
    }
}

extension MetricsAggregator {
    public mutating func group<Input>(evaluators: PropertyArrayEvaluators<Input>) {
        group(evaluators.accuracy.name) { group in
            group.computeMean(of: Metric(evaluators.equality.fullMetricName))
            group.computeMean(of: Metric(evaluators.accuracy.fullMetricName))
            group.computeMean(of: Metric(evaluators.completeness.fullMetricName))
            group.computeMean(of: Metric(evaluators.halucinations.fullMetricName))
        }
    }
}
