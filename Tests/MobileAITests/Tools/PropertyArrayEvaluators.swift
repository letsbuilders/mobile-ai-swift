//
//  PropertyArrayEvaluators.swift
//  AI
//
//  Created by Marzena on 17/09/2026.
//

import Evaluations

public struct PropertyArrayEvaluators<Input: Codable> {
    public let equality: PropertyEvaluator<Input>
    public let completeness: PropertyEvaluator<Input>
    public let accuracy: PropertyEvaluator<Input>
    public let halucinations: PropertyEvaluator<Input>

    // TODO: Finish
    @EvaluatorsBuilder<ModelSample<CodableResult<Input>>, ModelSubject<CodableResult<Input>>>
    public func evaluators() -> [any EvaluatorProtocol<ModelSample<CodableResult<Input>>, ModelSubject<CodableResult<Input>>>] {
        equality.evaluator()
        completeness.evaluator()
        accuracy.evaluator()
        halucinations.evaluator()
    }

    public init(name: String, keyPath: KeyPath<Input, [String]?>) {
        equality = PropertyEvaluator.equality(name: name, keyPath: keyPath)
        completeness = PropertyEvaluator.completeness(name: name, keyPath: keyPath)
        accuracy = PropertyEvaluator.accuracy(name: name, keyPath: keyPath)
        halucinations = PropertyEvaluator.hallucinations(name: name, keyPath: keyPath)
    }
}
