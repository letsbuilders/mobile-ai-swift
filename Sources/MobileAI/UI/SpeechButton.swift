//
//  SpeechButton.swift
//  AproplanAI
//
//  Created by Marzena on 07/07/2026.
//

#if !os(macOS)
import SwiftUI

public struct SpeechButton: View {
    @Binding var text: String

    @StateObject private var state: SpeechRecognizerState
    private var speechRecognizer: SpeechRecognizer

    public init(text: Binding<String>,
                speechRecognizer: SpeechRecognizer = .shared) {
        self._text = text
        self.speechRecognizer = speechRecognizer
        _state = StateObject(wrappedValue: speechRecognizer.state)
    }

    public var body: some View {
        Button {
            Task {
                let text = try await speechRecognizer.transcribe()

                await MainActor.run {
                    print("Update: \(text)")
                    self.text = text
                }
            }
        } label: {
            Image(systemName: state.isRecording ? "mic.fill" : "mic")
                .font(.title3)
                .foregroundStyle(state.isRecording ? .red : (state.isAuthorized && state.isAvailable ? .accentColor : .gray))
                .symbolEffect(.pulse, isActive: state.isRecording)
        }
        .buttonStyle(.plain)
        .disabled(!state.isAvailable || !state.isAuthorized)
        .onAppear {
            Task {
                await speechRecognizer.requestAuthorization()
            }
        }
    }
}

public extension SpeechButton {
    func onSubmit(_ action: @escaping (String) -> Void) -> some View {
        self
            .onChange(of: text) { text in
                action(text)
            }
    }
}
#endif
