//
//  AIComplexTextField.swift
//  MobileAI
//
//  Created by Marzena on 06/08/2026.
//

import SwiftUI

public struct AIComplexTextField<Handler: AIHandler>: View {
    @Binding private var model: AIModel<Handler>

    public init(model: Binding<AIModel<Handler>>) {
        self._model = model
    }

    public var body: some View {
        VStack {
            AIModelSelector(service: $model.handler.service)
            AITextField(model: $model)
        }
    }
}
