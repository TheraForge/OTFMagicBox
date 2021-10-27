//
//  Extension+Font.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 26/10/21.
//

import SwiftUI

extension Font {

    static var basicFontStyle: Font {
        return .system(size: 20, weight: .regular, design: .default)
    }
    
    static var subHeaderFontStyle: Font {
        return .system(size: 20, weight: .bold, design: .default)
    }
    
    static var headerFontStyle: Font {
        return .system(size: 25, weight: .bold, design: .default)
    }
    
    static var titleFontStyle: Font {
        return .system(size: 35, weight: .bold, design: .default)
    }

}

