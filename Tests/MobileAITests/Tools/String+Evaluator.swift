//
//  String+Evaluator.swift
//  AI
//
//  Created by Marzena on 10/09/2026.
//

import Evaluations
import NaturalLanguage

extension String {
    func accuracy(comparingTo other: String, language: NLLanguage = .english) -> MetricScore {
        guard let embedding = NLEmbedding.sentenceEmbedding(for: language) else {
            return MetricScore(.value(0.0), rationale: "Error: Not supported language \(language.rawValue)")
        }
        let distance = embedding.distance(between: self, and: other, distanceType: .cosine)
        let score = max(0.0, 1.0 - (distance / 2.0))
        return MetricScore(.value(score), rationale: "\(self) => \(other) (\(score.formatted(.number.precision(.fractionLength(2)))))")
    }
}

extension Metric {
    func accuracy(between expected: String?, and result: String?, language: NLLanguage = .english) -> Metric {
        guard let embedding = NLEmbedding.sentenceEmbedding(for: language) else {
            return failing(rationale: "Error: Not supported language \(language.rawValue)")
        }

        guard expected != result else {
            return scoring(1.0, rationale: "\(String(describing: result)) => \(String(describing: expected)) (1.0)")
        }

        guard let expected,
              let result else {
            return failing(rationale: "\(String(describing: result)) => \(String(describing: expected))")
        }

        let distance = embedding.distance(between: expected, and: result)
        return scoring(1.0 - distance, rationale: "\(self) => \(expected) (\(distance.formatted(.number.precision(.fractionLength(2)))))")
    }
}

extension MetricScore {
    static func accuracy(expected: String?, received: String?, language: NLLanguage) -> MetricScore {
        guard let embedding = NLEmbedding.sentenceEmbedding(for: language) else {
            return .scoring(0.0, rationale: "Error: Not supported language \(language.rawValue)")
        }

        guard expected != received else {
            return .scoring(1.0, expected: expected, received: received)
        }

        guard let expected,
              let received else {
            return .scoring(0.0, expected: expected, received: received)
        }

        let distance = embedding.distance(between: expected, and: received)
        return .scoring(1.0 - distance, expected: expected, received: received)
    }

    static func accuracy(expected: String?, received: String?) -> MetricScore {
        accuracy(expected: expected, received: received, language: .english)
    }

    static func equality<T: Equatable>(expected: T?, received: T?) -> MetricScore {
        if expected == received {
            return .passing(expected: expected, received: received)
        } else {
            return .failing(expected: expected, received: received)
        }
    }

    static func arrayEquality<T: Equatable>(expected: [T]?, received: [T]?) -> MetricScore where T: Comparable {
        if expected?.sorted() == received?.sorted() {
            return .passing(expected: expected, received: received)
        } else {
            return .failing(expected: expected, received: received)
        }
    }

    static func halucinations(expected: String?, received: String?) -> MetricScore {
        guard expected != received else {
            return .scoring(1.0, expected: expected, received: received)
        }

        if expected == nil {
            if received != nil {
                return .passing(expected: expected, received: received)
            } else {
                return .failing(expected: expected, received: received)
            }
        } else {
            return .failing(expected: expected, received: received)
        }
    }

    static func halucinations(expected: Bool?, received: Bool?) -> MetricScore {
        guard expected != received else {
            return .scoring(1.0, expected: expected, received: received)
        }

        if expected == nil {
            if received != nil {
                return .passing(expected: expected, received: received)
            } else {
                return .failing(expected: expected, received: received)
            }
        } else {
            return .failing(expected: expected, received: received)
        }
    }
}
