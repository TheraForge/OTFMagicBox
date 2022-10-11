//
//  Extension+Text.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/20/22.
//

import SwiftUI

extension Text {
    func regular(size: CGFloat) -> Text {
        self.font(.custom("\(YmlReader.shared.fontFamilyName)-Regular", size: size))
    }
    
    func light(size: CGFloat) -> Text {
        self.font(.custom("\(YmlReader.shared.fontFamilyName)-Light", size: size))
    }
    
    func medium(size: CGFloat) -> Text {
        self.font(.custom("\(YmlReader.shared.fontFamilyName)-Medium", size: size))
    }
    
    func semiBold(size: CGFloat) -> Text {
        self.font(.custom("\(YmlReader.shared.fontFamilyName)-SemiBold", size: size))
    }
    
    func bold(size: CGFloat) -> Text {
        self.font(.custom("\(YmlReader.shared.fontFamilyName)-Bold", size: size))
    }
}
