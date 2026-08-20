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
    @State private var isInstructionPresented = false
    @Binding private var model: AIModel

    public init(model: Binding<AIModel>) {
        self._model = model
    }

    public var body: some View {
        HStack {
            SpeechTextField(model.isInitialized ? "Enter prompt for AI or use microphone" : "Enter instructions for AI or use microphone",
                            text: $prompt)
            .onSubmit { prompt in
                guard !prompt.isEmpty else { return }
                Task {
                    await MainActor.run {
                        self.prompt = ""
                    }
                    try await model.submitPrompt(prompt)
                }
            }

            Button {
                isHistoryPresented = true
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)

            Button {
                isInstructionPresented = true
            } label: {
                Image(systemName: "list.clipboard")
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)

            if model.isProcessing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.small)
            }
        }
        .popoverSheet(isPresented: $isHistoryPresented, content: {
            AIChatHistoryView(history: $model.history)
                .navigationTitle("History")
        })
        .popoverSheet(isPresented: $isInstructionPresented, content: {
            TextField("Enter instructions for AI", text: $model.instructions, axis: .vertical)
                .lineLimit(3...8)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    isInstructionPresented = false
                }
                .navigationTitle("AI Instructions")
        })
        .onChange(of: model.instructions) { oldValue, newValue in
            if oldValue != newValue {
                model.reset()
            }
        }
    }
}

extension View {
    func popoverSheet<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        self
            .sheet(isPresented: isPresented, content: {
                Popover(isPresented: isPresented) {
                    content()
                }
            })
    }
}
