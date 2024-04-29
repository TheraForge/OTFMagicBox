//
//  OTFColor.swift
//  OTFMagicBox
//
//  Created by Tomas Martins on 06/07/23.
//

import SwiftUI

extension Color {
    static var otfTextColor: Color {
        if let uiColor = YmlReader().appStyle.textColor.color {
            return Color(uiColor)
        } else {
            return Color(UIColor.label)
        }
    }

    static var otfHeaderColor: Color {
        if let uiColor = YmlReader().appStyle.headerColor.color {
            return Color(uiColor)
        } else {
            return Color(UIColor.secondaryLabel)
        }
    }

    static var otfCellBackground: Color {
        if let uiColor = YmlReader().appStyle.cellbackgroundColor.color {
            return Color(uiColor)
        } else {
            return Color(UIColor.systemBackground)
        }
    }

    static var otfButtonColor: Color {
        if let uiColor = YmlReader().appStyle.buttonTextColor.color {
            return Color(uiColor)
        } else {
            return Color(UIColor.black)
        }
    }
    
    static var otfborderColor : Color {
        if let uiColor = YmlReader().appStyle.borderColor.color {
            return Color(uiColor)
        } else {
            return Color(UIColor.black)
        }
    }
    
    static var otfseparatorColor : Color {
        if let uiColor = YmlReader().appStyle.separatorColor.color {
            return Color(uiColor)
        } else {
            return Color(UIColor.black)
        }
    }
}
