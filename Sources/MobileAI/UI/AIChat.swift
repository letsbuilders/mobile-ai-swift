//
//  AIChat.swift
//  AproplanAI
//
//  Created by Marzena on 07/07/2026.
//

import SwiftUI

@available(iOS 26.0, *)
public struct AIChat: View {
    @State private var model: AIModel<TextAIHandler>

    public init(aiService: AIService,
                chat: [TextEntry] = []) {
        self.model = AIModel(handler: TextAIHandler(service: aiService),
                             showInstructionsButton: false)
    }

    public var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                AIChatHistoryView(history: $model.history)
                    .frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(.bottom)

            Spacer()

            AIComplexTextField(model: $model)
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
