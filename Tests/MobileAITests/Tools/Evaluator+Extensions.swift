//
//  Evaluator+Extensions.swift
//  AI
//
//  Created by Marzena on 10/09/2026.
//

import Evaluations

extension Metric {
    func composite(of metrics: [Metric]) -> Metric {
        var scores: [Double] = []
        var rationaleParts: [String] = []

        for metric in metrics {
            let scoreValue: Double

            switch metric.value {
            case .scoring(let value):
                scoreValue = value.isFinite ? value : 0.0
            case .passing:
                scoreValue = 1.0
            case .failing:
                scoreValue = 0.0
            @unknown default:
                scoreValue = 0.0
            }

            scores.append(scoreValue)
            rationaleParts.append("\(metric.name): \(scoreValue)")
        }

        let average = scores.isEmpty ? 0.0 : scores.reduce(0.0, +) / Double(scores.count)
        let combinedRationale = rationaleParts.joined(separator: ", ")

        return scoring(average, rationale: combinedRationale)
    }
}
