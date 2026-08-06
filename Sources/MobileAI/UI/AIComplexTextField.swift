//
//  AIComplexTextField.swift
//  MobileAI
//
//  Created by Marzena on 06/08/2026.
//

import SwiftUI

public struct AIComplexTextField: View {
    @State var service: AIService?
    @State var progress: Progress = Progress()

    public init() {}

    public var body: some View {
        VStack {
            AIModelSelector(service: $service)
            if let service {
                AITextField(service: service)
            }
        }
    }
}

#Preview {
    AIComplexTextField()
}
