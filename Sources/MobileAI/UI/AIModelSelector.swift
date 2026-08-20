//
//  AIModelSelector.swift
//  MobileAI
//
//  Created by Marzena on 06/08/2026.
//

import SwiftUI

public struct AIModelSelector: View {
    @State public var kind: AIModelKind = .appleIntelligence
    @Binding var service: AIService?
    @State private var progress: Progress = .init()
    @State private var error: Error?

    public init(service: Binding<AIService?>) {
        self._service = service
    }

    public func select(kind: AIModelKind) {
        do {
            self.kind = kind
            self.service = nil
            self.error = nil
            self.progress = Progress(totalUnitCount: 1)

            let service = try AIServiceFactory.make(kind: kind)

            Task {
                do {
                    try await service.downloadModel { progress in
                        self.progress = progress
                    }
                    await await MainActor.run {
                        self.service = service
                    }
                } catch {
                    self.progress = .init()
                    self.error = error
                }
            }
        } catch {
            self.error = error
        }
    }

    public var body: some View {
        HStack {
            Menu {
                ForEach(AIModelKind.allCases) { kind in
                    Button {
                        select(kind: kind)
                    } label: {
                        Image(systemName: kind.isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle")
                        Text(kind.name)
                        .fixedSize(horizontal: true, vertical: false)
                        .bold()
                        .foregroundStyle(kind.isDownloaded ?.green : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.gray)
                        .clipShape(Capsule())
                    }
                }
            } label: {
                Text(kind.name)
                .fixedSize(horizontal: true, vertical: false)
                .bold()
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.gray)
                .clipShape(Capsule())
            }
            .controlSize(ControlSize.large)

            if let error {
                Text(error.localizedDescription)
                    .bold()
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            } else if progress.isFinished == false {
                ProgressView(progress)
            } else {
                Spacer()
            }
        }
        .onAppear {
            select(kind: .appleIntelligence)
        }
    }
}

#Preview {
    AIModelSelector(service: .constant(nil))
}
