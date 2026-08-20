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
    public var instructions: String = ""
    public var isDownloaded: Bool = false
    public var isInitialized: Bool = false

    public var service: AIService?
    private var session: AISession?

    public init(service: AIService? = nil,
                instructions: String? = nil,
                adjustPrompt: @escaping (String) -> String = { $0 }) {
        self.service = service
        self.instructions = instructions ?? UserDefaults.standard.string(forKey: "AI.Instructions") ?? ""
        self.adjustPrompt = adjustPrompt

        observeService()
        observeInstructions()
    }

    private func observeService() {
        withObservationTracking {
            _ = service
        } onChange: {
            print("Changed service \(self.service)")
            self.reset()
            self.observeService()
        }
    }

    private func observeInstructions() {
        withObservationTracking {
            instructions
        } onChange: {
            DispatchQueue.main.async {
                UserDefaults.standard.set(self.instructions, forKey: "AI.Instructions")
                self.observeInstructions()
            }
        }
    }

    public func reset() {
        self.session = nil
        self.isInitialized = false
        self.history = []
    }

    public func submitPrompt(_ prompt: String) async throws {
        guard isProcessing == false, let service else { return }

        if session == nil {
            session = try service.startSession(instructions: instructions)
            if instructions.isEmpty == false {
                history.append(TextEntry(author: .me, text: instructions))
            }
            isInitialized = true
        }

        isProcessing = true
        defer { isProcessing = false }

        var fullPrompt = adjustPrompt(prompt)

        if let session {
            let date = Date.now
            do {
                history.append(TextEntry(author: .me, text: fullPrompt))
                let response = try await session.respond(to: fullPrompt)
                history.append(TextEntry(time: Date.now.timeIntervalSince(date), author: .ai, text: response.content))
                responsePublisher.send(response.content)
            } catch {
                history.append(TextEntry(time: Date.now.timeIntervalSince(date), author: .ai, error: error, text: ""))
            }
        }
    }
}

public struct TextEntry: Identifiable {
    public var id: String = UUID().uuidString
    public var time: TimeInterval = 0
    public var author: Author
    public var error: Error? = nil
    public var text: String
}

public typealias Author = String
public extension Author {
    static var me: Author { "ME" }
    static var ai: Author { "AI" }
}

