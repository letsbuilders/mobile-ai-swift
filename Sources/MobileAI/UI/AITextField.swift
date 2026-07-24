//
//  AITextField.swift
//  MobileAI
//
//  Created by Marzena on 23/07/2026.
//

import SwiftUI

public struct AITextField: View {
    @State private var prompt: String = ""
    @State private var history: [TextEntry] = []
    @State private var isHistoryPresented = false
    @State private var model: AIModel

    public init(model: AIModel) {
        self.model = model
    }

    public init(service: AIService? = nil) {
        model = .init(service: service)
    }

    public var body: some View {
        HStack {
            SpeechTextField("Enter prompt for AI or speak using microphone",
                            text: $prompt)
            .onSubmit { prompt in
                guard !prompt.isEmpty else { return }
                Task {
                    try await model.submitPrompt(prompt)
                    await MainActor.run {
                        self.prompt = ""
                    }
                }
            }

            Button {
                isHistoryPresented = true
            } label: {
                Image(systemName: "list.clipboard")
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)

            if model.isProcessing {
                ProgressView()
                    .frame(width: 16, height: 16)
            }
        }
        .sheet(isPresented: $isHistoryPresented, content: {
            NavigationStack {
                ScrollView {
                    AIChatHistoryView(history: $model.history)
                        .padding()
                }
                .defaultScrollAnchor(.bottom)
                .navigationTitle("History")
#if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.clear, for: .navigationBar)
#endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            isHistoryPresented = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        })
    }
}
