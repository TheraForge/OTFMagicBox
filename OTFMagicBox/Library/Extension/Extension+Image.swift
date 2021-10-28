//
//  Extension+Image.swift
//  OTFMagicBox
//
//  Created by Admin on 27/10/2021.
//

import SwiftUI

extension Image {
    static var theraforgeLogo: Image {
        UIImage.loadImage(named: "TheraforgeLogo")
            .resizable()
            .scaledToFit()
            .padding(.leading, Metrics.PADDING_HORIZONTAL_MAIN * 4)
            .padding(.trailing, Metrics.PADDING_HORIZONTAL_MAIN * 4) as! Image
    }
}
