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
        VStack(alignment: .leading) {
            if history.count == 0 {
                HStack {
                    Spacer()
                }
                Spacer()
            }

            ForEach(history) { textEntry in
                if textEntry.author == .me {
                    HStack {
                        Spacer()
                        Text(textEntry.text)
                            .textSelection(.enabled)
                            .roundedBackground(color: .black.opacity(0.05))
                            .padding(.leading, 40)
                    }
                } else {
                    Text("Generated in \(textEntry.time.prettyPrinted())")
                        .font(.footnote)
                    if let error = textEntry.error {
                        Text(error.localizedDescription)
                            .textSelection(.enabled)
                            .foregroundStyle(Color.red)
                    } else {
                        if let markdown = try? AttributedString(markdown: textEntry.text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                            Text(markdown)
                                .textSelection(.enabled)
                        } else {
                            Text(textEntry.text)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
    }
}

private extension TimeInterval {
    func prettyPrinted() -> String {
        Duration.seconds(self).formatted(
            .units(allowed: [.minutes, .seconds, .milliseconds], width: .abbreviated)
        )
    }
}
