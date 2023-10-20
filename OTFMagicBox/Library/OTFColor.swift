//
//  OTFColor.swift
//  OTFMagicBox
//
//  Created by Tomas Martins on 06/07/23.
//

import SwiftUI

extension Color {
    static var otfTextColor: Color {
        if let uiColor = YmlReader().appTheme?.textColor.color {
            return Color(uiColor)
        } else {
            return Color(UIColor.label)
        }
    }
    
    static var otfHeaderColor: Color {
        if let uiColor = YmlReader().appTheme?.headerColor.color {
            return Color(uiColor)
        } else {
            return Color(UIColor.secondaryLabel)
        }
    }
    
    static var otfCellBackground: Color {
        if let uiColor = YmlReader().appTheme?.cellbackgroundColor.color {
            return Color(uiColor)
        } else {
            return Color(UIColor.systemBackground)
        }
    }
    
    static var otfButtonColor: Color {
        if let uiColor = YmlReader().appTheme?.buttonTextColor.color {
            return Color(uiColor)
        } else {
            return Color(UIColor.black)
        }
    }
}
