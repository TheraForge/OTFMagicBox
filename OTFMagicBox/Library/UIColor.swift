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

extension UIColor {
    
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red, green, blue, alpha)
    }
    
    /// Returns  UIcolor for a given type of hex color.
    func getColor(colorValue: String) -> UIColor {
        let hex = colorValue
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}


public extension Color {
    
    private typealias PlatformColor = UIColor
    
    static var systemBlue: Color { Color(PlatformColor.systemBlue) }
    static var systemBrown: Color { Color(PlatformColor.systemBrown) }
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
    static var systemCyan: Color { Color(PlatformColor.systemCyan) }
    static var systemGreen: Color { Color(PlatformColor.systemGreen) }
    static var systemIndigo: Color { Color(PlatformColor.systemIndigo) }
    @available(iOS 15.0, macOS 10.15, tvOS 15.0, *)
    static var systemMint: Color { Color(PlatformColor.systemMint) }
    static var systemOrange: Color { Color(PlatformColor.systemOrange) }
    static var systemPink: Color { Color(PlatformColor.systemPink) }
    static var systemPurple: Color { Color(PlatformColor.systemPurple) }
    static var systemRed: Color { Color(PlatformColor.systemRed) }
    static var systemTeal: Color { Color(PlatformColor.systemTeal) }
    static var systemYellow: Color { Color(PlatformColor.systemYellow) }
    
    static var systemGray2: Color { Color(PlatformColor.systemGray2) }
    static var systemGray3: Color { Color(PlatformColor.systemGray3) }
    static var systemGray4: Color { Color(PlatformColor.systemGray4) }
    static var systemGray5: Color { Color(PlatformColor.systemGray5) }
    static var systemGray6: Color { Color(PlatformColor.systemGray6) }
    
    static var darkGray: Color { Color(PlatformColor.darkGray) }
    static var lightGray: Color { Color(PlatformColor.lightGray) }
    static var magenta: Color { Color(PlatformColor.magenta) }
    
    static var systemFill: Color { Color(PlatformColor.systemFill) }
    static var secondarySystemFill: Color { Color(PlatformColor.secondarySystemFill) }
    static var tertiarySystemFill: Color { Color(PlatformColor.tertiarySystemFill) }
    static var quaternarySystemFill: Color { Color(PlatformColor.quaternarySystemFill) }
    
    static var placeholderText: Color { Color(PlatformColor.placeholderText) }
    static var systemBackground: Color { Color(PlatformColor.systemBackground) }
    static var secondarySystemBackground: Color { Color(PlatformColor.secondarySystemBackground) }
    static var tertiarySystemBackground: Color { Color(PlatformColor.tertiarySystemBackground) }
    
    static var systemGroupedBackground: Color { Color(PlatformColor.systemGroupedBackground) }
    static var secondarySystemGroupedBackground: Color { Color(PlatformColor.secondarySystemGroupedBackground) }
    static var tertiarySystemGroupedBackground: Color { Color(PlatformColor.tertiarySystemGroupedBackground) }
    static var separator: Color { Color(PlatformColor.separator) }
    static var opaqueSeparator: Color { Color(PlatformColor.opaqueSeparator) }
    static var link: Color { Color(PlatformColor.link) }
    static var darkText: Color { Color(PlatformColor.darkText) }
    static var lightText: Color { Color(PlatformColor.lightText) }

}
