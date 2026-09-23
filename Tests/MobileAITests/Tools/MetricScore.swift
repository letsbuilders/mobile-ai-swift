//
//  MetricScore.swift
//  AI
//
//  Created by Marzena on 10/09/2026.
//

import Evaluations
import Foundation

public typealias MetricScoreFunction<Output> = @Sendable (Output, Output) -> MetricScore

public enum Score {
    case value(Double)
    case pass
    case fail

    var value: Double {
        switch self {
        case .value(let value): value
        case .pass: 1.0
        case .fail: 0.0
        }
    }
}

public struct MetricScore {
    public let score: Score
    public let rationale: String

    public init(_ value: Score, rationale: String = "") {
        self.score = value
        self.rationale = rationale
    }
}

public extension MetricScore {
    static func scoring(_ score: Double, rationale: String) -> MetricScore {
        MetricScore(.value(score), rationale: rationale)
    }

    static func scoring<Output>(_ score: Double, expected: Output, received: Output) -> MetricScore {
        MetricScore(.value(score), rationale: "Expected: \(String.display(expected)). Received: \(String.display(received)) (\(score.formatted(.number.precision(.fractionLength(2)))))")
    }

    static func failing<Output>(expected: Output, received: Output) -> MetricScore {
        MetricScore(.fail, rationale: "Expected: \(String.display(expected)). Received: \(String.display(received))")
    }

    static func passing<Output>(expected: Output, received: Output) -> MetricScore {
        MetricScore(.pass, rationale: "Expected: \(String.display(expected)). Received: \(String.display(received))")
    }
}

public extension Metric {
    func scoring(_ score: MetricScore) -> Self {
        switch score.score {
        case .value(let value):
            self.scoring(value, rationale: score.rationale)
        case .pass:
            self.passing(rationale: score.rationale)
        case .fail:
            self.failing(rationale: score.rationale)
        }
    }
}

public extension Array where Element == MetricScore {
    func mean() -> MetricScore {
        let allRationale: [String] = map { $0.rationale }
        let value: Double = reduce(0.0, { $0 + $1.score.value })

        return MetricScore(.value(count == 0 ? 0.0 : value / Double(count)),
                           rationale: allRationale.joined(separator: ", "))
    }
}

private extension String {
    static func display(_ value: Any) -> String {
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            if let first = mirror.children.first {
                return display(first.value)
            } else {
                return "nil"
            }
        } else {
            return String(describing: value)
        }
    }
}

public extension MetricScore {
    static func zero<Input>() -> MetricScoreFunction<Input> {
        { _, _ in MetricScore(.value(0.0)) }
    }
}
