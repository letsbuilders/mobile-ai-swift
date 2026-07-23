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
    @State private var buttonContent: String = ""
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
                    Log.info(Self.self, "Submit content from field: \(textFieldContent)")
                    self.text = textFieldContent
                }
                .style(isFocused: isFocused)
                .animation(.easeOut(duration: 0.15), value: isFocused)

#if !os(macOS)
            SpeechButton(text: $buttonContent)
                .onSubmit { text in
                    Log.info(Self.self, "Submit content from speech button: \(text)")
                    self.text = text
                }
#endif
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

private extension View {
    func style(isFocused: Bool) -> some View {
        #if !os(macOS)
            self.roundedBackground(color: Color(.secondarySystemBackground), borderColor: isFocused ? Color.accentColor : Color.clear)
        #else
            self
        #endif
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
