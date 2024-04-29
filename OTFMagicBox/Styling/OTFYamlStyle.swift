//
//  OTFYamlStyle.swift
//  OTFMagicBox
//
//  Created by Tomas Martins on 06/02/24.
//

import SwiftUI
import OTFDesignSystem
import OTFCareKitUI

class OTFYamlStyle: OTFDesignStyler {
    var color: OTFDesignStylerColor
    
    init(style: ThemeCustomization) {
        self.color = StylerColor(style: style)
    }
}

extension OTFYamlStyle {
    class StylerColor: OTFDesignStylerColor {
        var label: Color
        var secondaryLabel: Color
        var separator: Color
        var customFill: Color
        var customGray: Color
        var primaryButton: Color
        var customBackground: Color
        
        init(style: ThemeCustomization) {
            if let backgroundColor = style.backgroundColor.color {
                self.customBackground = Color(backgroundColor)
            } else {
                self.customBackground = .systemBackground
            }
            
            if let textColor = style.textColor.color {
                self.label = Color(textColor)
            } else {
                self.label = Color(UIColor.label)
            }
            
            if let separatorColor = style.separatorColor.color {
                self.separator = Color(separatorColor)
            } else {
                self.separator = Color.separator
            }
            
            if let cellBackgroundColor = style.cellbackgroundColor.color {
                self.customFill = Color(cellBackgroundColor)
            } else {
                self.customFill = Color.tertiarySystemFill
            }
            
            if let buttonTextColor = style.buttonTextColor.color {
                self.primaryButton = Color(buttonTextColor)
            } else {
                self.primaryButton = Color.systemBlue
            }
            
            if let borderColor = style.borderColor.color {
                self.customGray = Color(borderColor)
            } else {
                self.customGray = Color(UIColor.systemGray)
            }
            
            if let headerColor = style.headerColor.color {
                self.secondaryLabel = Color(headerColor)
            } else {
                self.secondaryLabel = Color(UIColor.secondaryLabel)
            }
        }

    }
}
