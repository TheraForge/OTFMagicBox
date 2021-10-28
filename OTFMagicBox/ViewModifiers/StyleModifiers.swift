//
//  StyleModifiers.swift
//  OTFMagicBox
//
//  Created by Admin on 28/10/2021.
//

import SwiftUI

enum CustomStyle {
    case emailField
    case secureField
}

extension View {
    @ViewBuilder func style(_ style: CustomStyle) -> some View {
        switch style {
        case .emailField:
            self.autocapitalization(.none)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.black, style: StrokeStyle(lineWidth: 1.0)))
                .padding()
            
        case .secureField:
            self.padding()
                .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.black, style: StrokeStyle(lineWidth: 1.0)))
                .padding()
        }
    }
}
