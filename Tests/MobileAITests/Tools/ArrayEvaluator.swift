//
//  ArrayEvaluator.swift
//  AI
//
//  Created by Marzena on 27/08/2026.
//

import Evaluations
import Foundation
import NaturalLanguage

public struct ArrayEvaluator {
    let langugage: NLLanguage
    let expected: [String]
    let received: [String]

    init(langugage: NLLanguage = .english,
         expected: [String],
         received: [String]) {
        self.langugage = langugage
        self.expected = expected
        self.received = received
    }

    func isSubset() -> Bool {
        Set(received).isSubset(of: Set(expected))
    }

    func isSuperset() -> Bool {
        Set(received).isSuperset(of: Set(expected))
    }

    func accuracyScore() -> MetricScore {
        var total = 1.0
        let received = Set(received)
        var results: [String] = []

        for element in expected {
            let bestMatch = received.bestMatching(element)
            if results.isEmpty {
                total = bestMatch.score.value
            } else {
                total = (total + bestMatch.score.value) / 2.0
            }
            results.append("\(bestMatch.rationale) => \(element) (\(bestMatch.score.value.formatted(.number.precision(.fractionLength(2)))))")
        }
        return MetricScore(.value(total), rationale: "Matching: \(results.listDescription)")
    }

    func hallucinationsScore() -> MetricScore {
        let hallucinated = Set(received).subtracting(Set(expected))
            .filter {
                let bestMatch = expected.bestMatching($0)
                return bestMatch.score.value < 0.5
            }
        if hallucinated.isEmpty {
            return MetricScore(.value(0.0))
        }
        return MetricScore(.value(received.count == 0 ? 0.0 : Double(hallucinated.count) / Double(received.count)),
                           rationale: "Hallucinated: \(hallucinated.listDescription)")
    }

    func completenessScore() -> MetricScore {
        let missing = Set(expected).subtracting(Set(received))
            .filter {
                let bestMatch = received.bestMatching($0)
                return bestMatch.score.value < 0.5
            }
        if missing.isEmpty {
            return MetricScore(.value(1.0), rationale: "Received: \(received.listDescription). Expected: \(expected.listDescription)")
        }

        return MetricScore(.value(expected.count == 0 ? 0.0 : (Double(expected.count) - Double(missing.count)) / Double(expected.count)),
                           rationale: "Missing: \(missing.listDescription)")
    }
}

public extension ArrayEvaluator {
    var accuracy: Metric {
        Metric("Accuracy").scoring(accuracyScore())
    }

    var completeness: Metric {
        Metric("Completeness").scoring(completenessScore())
    }

    var hallucinations: Metric {
        Metric("Hallucinations").scoring(hallucinationsScore())
    }
}

private extension Array where Element: CustomStringConvertible {
    var listDescription: String {
        self.map { $0.description }.joined(separator: ", ")
    }
}

private extension Set where Element: CustomStringConvertible {
    var listDescription: String {
        self.map { $0.description }.sorted().joined(separator: ", ")
    }
}

private extension Set where Element == String {
    func bestMatching(_ template: String) -> MetricScore {
        var bestMatch = MetricScore(.value(0.0))
        for element in self {
            let score = element.accuracy(comparingTo: template).score
            if score.value > bestMatch.score.value {
                bestMatch = .scoring(score.value, expected: template, received: element)
            }
        }
        return bestMatch
    }
}

private extension Array where Element == String {
    func bestMatching(_ template: String) -> MetricScore {
        Set(self).bestMatching(template)
    }
}
