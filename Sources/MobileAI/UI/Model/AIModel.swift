//
//  AIModel.swift
//  MobileAI
//
//  Created by Marzena on 24/07/2026.
//

import Combine
import FoundationModels
import SwiftUI

public protocol AIHandler {
    associatedtype Response

    var service: AIService { get set }
    var instructions: String { get set }

    func reset()
    func submitPrompt(_ prompt: String) async throws -> Response
}

public class TextAIHandler: AIHandler {
    public var responsePublisher: PassthroughSubject<Result<String, Error>, Never> = .init()
    public var service: AIService
    public var instructions: String = ""
    public var isInitialized: Bool = false
    public var tools: [Any] = []

    private var session: AISession?

    public init(service: AIService,
                instructions: String? = nil) {
        self.service = service
        self.instructions = instructions ?? UserDefaults.standard.string(forKey: "AI.Instructions") ?? ""
    }

    public func reset() {
        self.session = nil
        self.isInitialized = false
    }

    public func startSessionIfNeeded() throws -> AISession {
        if let session {
            return session
        } else {
            let session = try service.startSession(instructions: self.instructions, maxTokens: nil)
            self.session = session
            return session
        }
    }

    public func submitPrompt(_ prompt: String) async throws -> String {
        do {
            let response = try await startSessionIfNeeded().respond(to: prompt).content
            responsePublisher.send(.success(response))
            return response
        } catch {
            responsePublisher.send(.failure(error))
            throw error
        }
    }
}

@available(iOS 26.0, *)
public class GenerableAIHandler<Entity: Generable>: AIHandler {
    public var generablePublisher: PassthroughSubject<Result<Entity, Error>, Never> = .init()
    public var service: AIService
    public var instructions: String = ""
    public var isProcessing = false
    public var isInitialized: Bool = false
    public var tools: [any Tool] = []
    public var schema: GenerationSchema?

    private var session: AISession?

    public init(service: AIService,
                instructions: String? = nil,
                schema: GenerationSchema? = nil,
                tools: [any Tool],
                adjustPrompt: @escaping (String) -> String = { $0 }) {
        self.service = service
        self.instructions = instructions ?? UserDefaults.standard.string(forKey: "AI.Instructions") ?? ""
        self.schema = schema
        self.tools = tools
    }

    public func reset() {
        self.session = nil
        self.isInitialized = false
    }

    public func startSessionIfNeeded() throws -> AISession {
        if let session {
            return session
        } else {
            let session = try service.startSession(instructions: self.instructions,
                                                   tools: tools,
                                                   maxTokens: nil)
            self.session = session
            return session
        }
    }

    public func submitPrompt(_ prompt: String) async throws -> Entity {
        let session = try startSessionIfNeeded()
        do {
            let response = try await session.generate(from: prompt, type: Entity.self)
            generablePublisher.send(.success(response))
            return response
        } catch {
            generablePublisher.send(.failure(error))
            throw error
        }
    }
}

@available(iOS 26.0, *)
public class SchemaAIHandler: AIHandler {
    public var generablePublisher: PassthroughSubject<Result<GeneratedContent, Error>, Never> = .init()
    public var service: AIService
    public var instructions: String = ""
    public var isProcessing = false
    public var isInitialized: Bool = false
    public var tools: [any Tool] = []
    public var schema: GenerationSchema

    private var session: AISession?

    public init(service: AIService,
                instructions: String? = nil,
                schema: GenerationSchema,
                tools: [any Tool],
                adjustPrompt: @escaping (String) -> String = { $0 }) {
        self.service = service
        self.instructions = instructions ?? UserDefaults.standard.string(forKey: "AI.Instructions") ?? ""
        self.schema = schema
        self.tools = tools

        print("AI: Schema: \(schema)")
    }

    public func reset() {
        self.session = nil
        self.isInitialized = false
    }

    public func startSessionIfNeeded() throws -> AISession {
        if let session {
            return session
        } else {
            let session = try service.startSession(instructions: self.instructions,
                                                   tools: tools,
                                                   maxTokens: nil)
            self.session = session
            return session
        }
    }

    public func submitPrompt(_ prompt: String) async throws -> GeneratedContent {
        let session = try startSessionIfNeeded()
        do {
            let response = try await session.respond(to: prompt, schema: schema)
            generablePublisher.send(.success(response))
            return response
        } catch {
            generablePublisher.send(.failure(error))
            throw error
        }
    }
}


@Observable
public class AIModel<Handler: AIHandler> {
    public var isProcessing = false
    public var history: [TextEntry] = []
    public var adjustPrompt: (String) -> String
    public var instructions: String = ""
    public var isInitialized: Bool = true
    public var isDownloaded: Bool = false
    public var tools: [Any] = []
    public var generableType: Any.Type? = nil
    public var handler: Handler
    public var showMicrophoneButton = false
    public var showInstructionsButton = false

    public init(handler: Handler,
                instructions: String? = nil,
                showMicrophoneButton: Bool = true,
                showInstructionsButton: Bool = false,
                adjustPrompt: @escaping (String) -> String = { $0 }) {
        var handler = handler
        handler.instructions = instructions ?? UserDefaults.standard.string(forKey: "AI.Instructions") ?? ""

        self.handler = handler
        self.instructions = handler.instructions
        self.adjustPrompt = adjustPrompt
        self.showMicrophoneButton = showMicrophoneButton
        self.showInstructionsButton = showInstructionsButton

        observeHandler()
        observeInstructions()
    }

    private func observeHandler() {
        withObservationTracking {
            _ = handler
        } onChange: {
            print("Changed AI handler \(self.handler)")
            self.reset()
            self.observeHandler()
        }
    }

    private func observeInstructions() {
        withObservationTracking {
            instructions
        } onChange: {
            DispatchQueue.main.async {
                self.handler.instructions = self.instructions
                self.handler.reset()
                UserDefaults.standard.set(self.instructions, forKey: "AI.Instructions")
                self.observeInstructions()
            }
        }
    }

    public func reset() {
        self.handler.reset()
        self.history = []
    }

    public func submitPrompt(_ prompt: String) async throws {
        guard isProcessing == false else { return }

        isProcessing = true
        defer { isProcessing = false }

        let fullPrompt = adjustPrompt(prompt)

        let date = Date.now
        do {
            history.append(TextEntry(author: .me, text: fullPrompt))
            let response = try await handler.submitPrompt(fullPrompt)
            history.append(TextEntry(time: Date.now.timeIntervalSince(date), author: .ai, text: String(describing: response)))
        } catch {
            history.append(TextEntry(time: Date.now.timeIntervalSince(date), author: .ai, error: error, text: ""))
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

