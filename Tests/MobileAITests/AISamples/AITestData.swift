//
//  AITestData.swift
//  AI
//
//  Created by Marzena on 16/09/2026.
//

import Foundation
import Evaluations

public struct AITestDescriptor<Expected: Codable>: Codable {
    public let prompt: String
    public let date: String
    public let instructionsFile: String
    public let catalogFile: String
    public let expected: Expected
}

public struct AITest<Expected: Codable>: Codable {
    public let prompt: String
    public let date: String
    public let instructions: String
    public let expected: Expected
}

public class AITestData {
    public func loadSamples<Expected: Codable>(prefix: String, type: Expected.Type) -> [ModelSample<CodableResult<Expected>>]{
        do {
            let descriptors = try loadTestDescriptors(prefix: prefix, type: type)
            return descriptors.map { ModelSample(prompt: $0.prompt,
                                                 expected: .success(result: $0.expected),
                                                 instructions: $0.instructions)}
        } catch {
            print(error)
            preconditionFailure()
        }
    }

    private func loadTestDescriptors<Expected: Codable>(prefix: String, type: Expected.Type) throws -> [AITest<Expected>] {
        let bundle = Bundle(for: Self.self)
        var counter = 1
        var results = [AITest<Expected>]()

        repeat {
            let fileName = "\(prefix)test\(String(format: "%03d", counter))"
            if let url = bundle.url(forResource: fileName, withExtension: "json") {
                let data = try Data(contentsOf: url)
                let descriptor = try JSONDecoder().decode(AITestDescriptor<Expected>.self, from: data)
                guard let catalogUrl = bundle.url(forResource: descriptor.catalogFile, withExtension: nil) else {
                    preconditionFailure("Catalog file \(descriptor.catalogFile) not found")
                }
                guard let instructionsUrl = bundle.url(forResource: descriptor.instructionsFile, withExtension: nil) else {
                    preconditionFailure("Instructions file \(descriptor.instructionsFile) not found")
                }
                let catalog = try String(contentsOf: catalogUrl, encoding: .utf8)
                let instructions = try String(contentsOf: instructionsUrl, encoding: .utf8)
                    .replacingOccurrences(of: "$(DATE)", with: descriptor.date)
                    .replacingOccurrences(of: "$(CATALOG)", with: catalog)
                results.append(AITest(prompt: descriptor.prompt,
                                      date: descriptor.date,
                                      instructions: instructions,
                                      expected: descriptor.expected))
                print(catalog)
                print(instructions)
                counter += 1
            } else {
                counter = -1
            }
        } while counter > 0

        return results
    }
}
