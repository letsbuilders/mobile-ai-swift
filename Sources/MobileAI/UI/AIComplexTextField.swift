//
//  AIComplexTextField.swift
//  MobileAI
//
//  Created by Marzena on 06/08/2026.
//

import SwiftUI

public struct AIComplexTextField: View {
    @Binding private var model: AIModel

    public init(model: Binding<AIModel>) {
        self._model = model
    }

    public var body: some View {
        VStack {
            AIModelSelector(service: $model.service)
            if model.service != nil {
                AITextField(model: $model)
            }
        }
    }
}

#Preview {
    AIComplexTextField(model: .constant(.init()))
}
