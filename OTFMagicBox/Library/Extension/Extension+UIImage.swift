/*
Copyright (c) 2021, Hippocrates Technologies S.r.l.. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of the copyright holder(s) nor the names of any contributor(s) may
be used to endorse or promote products derived from this software without specific
prior written permission. No license is granted to the trademarks of the copyright
holders even if such marks are included in this software.

4. Commercial redistribution in any form requires an explicit license agreement with the
copyright holder(s). Please contact support@hippocratestech.com for further information
regarding licensing.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.
 */

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
    static func loadImage(named: String) -> Image {
        if let sfImage = UIImage(systemName: named){
            return Image(uiImage: sfImage)
        }
        return Image(named)
    }
    
    func crop(to size: CGSize) -> UIImage? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        
        let widthRatio = size.width / CGFloat(cgImage.width)
        let heightRatio = size.height / CGFloat(cgImage.height)
        let scale = max(widthRatio, heightRatio)
        
        let scaledWidth = CGFloat(cgImage.width) * scale
        let scaledHeight = CGFloat(cgImage.height) * scale
        
        let xOffset = (scaledWidth - size.width) / 2
        let yOffset = (scaledHeight - size.height) / 2
        
        let targetRect = CGRect(x: -xOffset, y: -yOffset, width: scaledWidth, height: scaledHeight)
        
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        draw(in: targetRect)
        let croppedAndFilledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return croppedAndFilledImage
    }
}
