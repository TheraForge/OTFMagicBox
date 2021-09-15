//
//  Extension+String.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 10/09/21.
//

import Foundation
import UIKit

/**
  Extension of String to check the Emoji string.
 */
extension String {
    
    // Returns true if the given string contains Emoji.
    func containsEmojis() -> Bool {
        if count == 0 {
            return false
        }
        for character in self {
            if character.isEmoji {
                return true
            }
        }
        return false
    }

}
