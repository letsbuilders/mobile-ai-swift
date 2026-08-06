//
//  Popover.swift
//  MobileAI
//
//  Created by Marzena on 06/08/2026.
//

import SwiftUI

public struct Popover<Content: View>: View {
    @Binding var isPresented: Bool
    @ViewBuilder var content: () -> Content

    public var body: some View {
        NavigationStack {
            ScrollView {
                content()
                    .padding()
            }
            .defaultScrollAnchor(.bottom)
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
