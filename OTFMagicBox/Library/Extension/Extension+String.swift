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
 Extension of String to check the Emoji string.
 */
extension String {
    
    // Returns true if the given string contains Emoji.
    var containsEmojis: Bool {
        if count == 0 {
            return false
        }
        for character in self where character.isEmoji {
            return true
        }
        return false
    }
    
    // swiftlint:disable all
    var color: UIColor? {
        switch self {
        case "Red":
            return UIColor.red
        case "Green":
            return UIColor.green
        case "Indigo":
            return UIColor.systemIndigo
        case "Purple":
            return UIColor.purple
        case "Blue":
            return UIColor.blue
        case "Brown":
            return UIColor.brown
        case "Orange":
            return UIColor.orange
        case "Cyan":
            return UIColor.cyan
        case "Teal":
            return UIColor.systemTeal
        case "Yellow":
            return UIColor.yellow
        case "Pink":
            return UIColor.systemPink
        case "Gray":
            return UIColor.gray
        case "Black":
            return UIColor.black
        case "White":
            return UIColor.white
        case "systemRed":
            return UIColor.systemRed
        case "systemOrange":
            return UIColor.systemOrange
        case "systemYellow":
            return UIColor.systemYellow
        case "systemGreen":
            return UIColor.systemGreen
        case "systemMint":
            if #available(iOS 15.0, *) {
                return UIColor.systemMint
            } else {
                return UIColor.label
            }
        case "systemTeal":
            return UIColor.systemTeal
        case "systemCyan":
            if #available(iOS 15.0, *) {
                return UIColor.systemCyan
            } else {
                return UIColor.label
            }
        case "systemBlue":
            return UIColor.systemBlue
        case "systemIndigo":
            return UIColor.systemIndigo
        case "systemPurple":
            return UIColor.systemPurple
        case "systemPink":
            return UIColor.systemPink
        case "systemBrown":
            return UIColor.systemBrown
        case "systemGray":
            return UIColor.systemGray
        case "systemGray2":
            return UIColor.systemGray2
        case "systemGray3":
            return UIColor.systemGray3
        case "systemGray4":
            return UIColor.systemGray4
        case "systemGray5":
            return UIColor.systemGray5
        case "systemGray6":
            return UIColor.systemGray6
        case "label":
            return UIColor.label
        case "secondaryLabel":
            return UIColor.secondaryLabel
        case "tertiaryLabel":
            return UIColor.tertiaryLabel
        case "quaternaryLabel":
            return UIColor.quaternaryLabel
        case "placeholderText":
            return UIColor.placeholderText
        case "separator":
            return UIColor.separator
        case "opaqueSeparator":
            return UIColor.opaqueSeparator
        case "link":
            return UIColor.link
        case "systemGroupedBackground":
            return UIColor.systemGroupedBackground
        case "secondarySystemGroupedBackground":
            return UIColor.secondarySystemGroupedBackground
        case "tertiarySystemGroupedBackground":
            return UIColor.tertiarySystemGroupedBackground
        case "systemBackground":
            return UIColor.systemBackground
        case "secondarySystemBackground":
            return UIColor.secondarySystemBackground
        case "tertiarySystemBackground":
            return UIColor.tertiarySystemBackground
        default:
            return nil
        }
    }
    
    var fontWeight: Font.Weight? {
        
        switch self {
        case "Thin":
            return Font.Weight.thin
        case "Heavy":
            return Font.Weight.heavy
        case "Light":
            return Font.Weight.light
        case "Bold":
            return Font.Weight.bold
        case "Medium":
            return Font.Weight.medium
        case "Regular":
            return Font.Weight.regular
        case "SemiBold":
            return Font.Weight.semibold
        case "UltraLight":
            return Font.Weight.ultraLight
        case "Black":
            return Font.Weight.black
        default:
            return nil
        }
    }
    
    
    var appFont: Font? {
        
        switch self {
        case "Basic":
            return Font.basicFontStyle
        case "Header":
            return Font.headerFontStyle
        case "SubHeader":
            return Font.subHeaderFontStyle
        case "TitleStyle":
            return Font.titleFontStyle
        case "Body":
            return Font.body
        case "Callout":
            return Font.callout
        case "Caption":
            return Font.caption
        case "Caption2":
            return Font.caption2
        case "Footnote":
            return Font.footnote
        case "Headline":
            return Font.headline
        case "LargeTitle":
            return Font.largeTitle
        case "Subheadline":
            return Font.subheadline
        case "Title":
            return Font.title
        case "Title2":
            return Font.title2
        case "Title3":
            return Font.title3
        case "Inherited":
            return Font.basicFontStyle
        case "HeaderInherited":
            return Font.title3
        default:
            return nil
        }
    }
    
    var isValidEmail: Bool {
        NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}").evaluate(with: self)
    }
}
