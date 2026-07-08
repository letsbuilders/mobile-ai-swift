//
//  AIChat.swift
//  AproplanAI
//
//  Created by Marzena on 07/07/2026.
//

import SwiftUI

@available(iOS 26.0, *)
public struct AIChat: View {
    @State private var prompt: String = ""
    @State private var chat: [TextEntry]
    @State private var isRunning = false
    @FocusState private var isFocused: Bool
    private var aiService: AIService

    public init(aiService: AIService,
                chat: [TextEntry] = []) {
        self.aiService = aiService
        self.chat = chat
    }

    public var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                ForEach(chat) { textEntry in
                    if textEntry.author == .me {
                        HStack {
                            Spacer()
                            Text(textEntry.text)
                                .roundedBackground(color: .black.opacity(0.05))
                                .padding(.leading, 40)
                        }
                    } else {
                        if let markdown = try? AttributedString(markdown: textEntry.text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                            Text(markdown)
                        } else {
                            Text(textEntry.text)
                        }
                    }
                }
            }
            .defaultScrollAnchor(.bottom)

            if isRunning {
                ProgressView()
                    .padding()
                    .fillHorizontally()
            }

            Spacer()

            SpeechTextField(text: $prompt)
                .onSubmit { prompt in
                    guard !prompt.isEmpty else { return }
                    print("Prompt: \(prompt)")
                    Task {
                        chat.append(TextEntry(author: .me, text: prompt))
                        self.prompt = ""

                        isRunning = true
                        let response = try await aiService.respond(to: prompt)
                        defer {
                            isRunning = false
                        }
                        chat.append(TextEntry(author: .ai, text: response.content))
                    }
                }
        }
        .padding()
    }
}

public extension View {
    func fillHorizontally()  -> some View {
        HStack {
            Spacer()
            self
            Spacer()
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

#Preview {
    if #available(iOS 26.0, *) {
        AIChat(aiService: try! AppleIntelligence(),
            chat: [
            .init(author: .me, text: "This is my question"),
            .init(author: .ai, text: "Responding"),
            .init(author: .me, text: "Asking again")
        ])
    }
}
