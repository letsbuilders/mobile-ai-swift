//
//  SpeechTextField.swift
//  AproplanAI
//
//  Created by Marzena on 07/07/2026.
//

import SwiftUI

public struct SpeechTextField: View, Loggable {
    var placeholder: String
    @Binding var text: String

    @State private var textFieldContent: String = ""
    @State private var showPermissionAlert = false
    @FocusState private var isFocused: Bool

    public init(_ placeholder: String = "Type or tap the mic to speak",
                text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $textFieldContent)
                .submitLabel(.done)
                .focused($isFocused)
                .onSubmit {
                    self.text = textFieldContent
                }
                .roundedBackground(color: Color(.secondarySystemBackground), borderColor: isFocused ? Color.accentColor : Color.clear)
                .animation(.easeOut(duration: 0.15), value: isFocused)

            SpeechButton(text: $textFieldContent)
                .onSubmit { text in
                    self.text = text
                }
        }
        .onChange(of: text) { oldValue, newValue in
            if textFieldContent != newValue {
                textFieldContent = newValue
            }
        }
    }
}

public extension SpeechTextField {
    func onSubmit(_ action: @escaping (String) -> Void) -> some View {
        self
            .onChange(of: text) { text in
                action(text)
            }
    }
}

public extension View {
    func roundedBackground(color: Color, borderColor: Color = .clear) -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1.5)
            )
    }
}
