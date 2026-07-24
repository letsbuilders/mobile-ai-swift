//
//  AIChatHistoryView.swift
//  MobileAI
//
//  Created by Marzena on 24/07/2026.
//

import SwiftUI

public struct AIChatHistoryView: View {
    @Binding private var history: [TextEntry]

    public init(history: Binding<[TextEntry]>) {
        self._history = history
    }

    public var body: some View {
        ForEach(history) { textEntry in
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
}
