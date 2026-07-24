//
//  AIModel.swift
//  MobileAI
//
//  Created by Marzena on 24/07/2026.
//

import Combine
import SwiftUI

@Observable
public class AIModel {
    public var responsePublisher: PassthroughSubject<String, Never> = .init()
    public var isProcessing = false
    public var history: [TextEntry] = []
    public var adjustPrompt: (String) -> String
    public var instructions: String?

    private var service: AIService?
    private var isInitialized: Bool = false

    public init(service: AIService? = nil,
                instructions: String? = nil,
                adjustPrompt: @escaping (String) -> String = { $0 }) {
        self.service = service
        self.instructions = instructions
        self.adjustPrompt = adjustPrompt
    }

    public func submitPrompt(_ prompt: String) async throws {
        guard isProcessing == false else { return }

        isProcessing = true
        defer { isProcessing = false }

        var fullPrompt = prompt
        if isInitialized {
            fullPrompt = adjustPrompt(prompt)
        } else {
            if let instructions {
                fullPrompt = instructions
                fullPrompt += "\n"
                fullPrompt += adjustPrompt(prompt)
            }

            isInitialized = true
        }

        if let service {
            let response = try await service.respond(to: fullPrompt)
            history.append(TextEntry(author: .me, text: fullPrompt))
            history.append(TextEntry(author: .ai, text: response.content))
            responsePublisher.send(response.content)
        }
    }
}

public struct TextEntry: Identifiable {
    public var id: String = UUID().uuidString
    public var author: Author
    public var text: String
}

public typealias Author = String
public extension Author {
    static var me: Author { "ME" }
    static var ai: Author { "AI" }
}

