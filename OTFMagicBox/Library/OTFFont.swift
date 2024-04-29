//
//  OTFFont.swift
//  OTFMagicBox
//
//  Created by Waqas Khadim on 25/10/2023.
//

import SwiftUI

extension Font {
    static var otfAppFont : Font {
        if let font = YmlReader().appStyle.textFont.appFont {
            return font
        } else {
            return Font.system(size: 17.0)
        }
    }
    
    static var otfFontWeight : Font.Weight? {
        return YmlReader().appStyle.textWeight.fontWeight
    }
    
    static var otfscreenTitleFont : Font {
        if let font =  YmlReader().appStyle.screenTitleFont.appFont {
            return font
        } else {
            return Font.system(size: 17.0)
        }
    }
    
    static var otfscreenTitleFontWeight : Font.Weight? {
        return YmlReader().appStyle.screenTitleFont.fontWeight
    }
    
    static var otfheaderTitleFont : Font {
        if let font = YmlReader().appStyle.headerTitleFont.appFont {
            return font
        } else {
            return Font.system(size: 17.0)
        }
    }
    
    static var otfheaderTitleWeight : Font.Weight? {
        return YmlReader().appStyle.headerTitleWeight.fontWeight
    }
}
