//
//  Extensions+UIImage.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 10/09/21.
//

import Foundation
import UIKit
import SwiftUI

/**
  Extension of UIImage to load the Image depending on its image type.
 */
extension UIImage {

    // Checks whether the given image is a SF symbol, if not returns it as a normal image.
    /**
     Checks whether the given image is a SF symbol, if not returns it as a normal image.
     
    Remark:- Use this method to display any of the images in your application. This method supports all kind of images like SF Symbols or any images saved from          Assets.
     */
    static func loadImage (named: String) -> Image {
        if let sfImage = UIImage(systemName: named){
            return Image(uiImage: sfImage)
        }
        return Image(named)
    }

}
