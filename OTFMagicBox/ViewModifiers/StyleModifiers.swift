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
    case textField
}

extension View {
    
    var colorScheme: ColorScheme {
        Environment(\.colorScheme).wrappedValue
    }
    
    @ViewBuilder func style(_ style: CustomStyle) -> some View {
        let color = colorScheme == .dark ? Color.white : .black
        switch style {
        case .emailField:
            self.autocapitalization(.none)
                .padding()
                .overlay(Capsule().strokeBorder(color, style: StrokeStyle(lineWidth: 1.0)))
                .padding()
            
        case .textField:
            self.autocapitalization(.none)
                .padding()
                .overlay(Capsule().strokeBorder(color, style: StrokeStyle(lineWidth: 1.0)))
                .padding()
            
        case .secureField:
            self.padding()
                .overlay(Capsule().strokeBorder(color, style: StrokeStyle(lineWidth: 1.0)))
                .padding()
        }
    }
}


extension Image {
    func logoStyle() -> some View {
        self.resizable()
            .scaledToFit()
            .padding(.leading, Metrics.PADDING_HORIZONTAL_MAIN * 4)
            .padding(.trailing, Metrics.PADDING_HORIZONTAL_MAIN * 4)
    }
    
    func iconStyle() -> some View {
        self.resizable()
            .clipped()
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.blue, lineWidth: 2.0))
    }
}

