//
//  CheckboxToggleStyle.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import SwiftUI

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .blue : .secondary)
                    .font(.system(size: 18))
                
                configuration.label
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}