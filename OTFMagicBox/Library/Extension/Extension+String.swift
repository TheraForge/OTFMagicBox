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
        case "Gray2":
                return UIColor.systemGray2
        case "Gray3":
                return UIColor.systemGray3
        case "Gray4":
                return UIColor.systemGray4
        case "Gray5":
                return UIColor.systemGray5
        case "Gray6":
                return UIColor.systemGray6
        case "Black":
                return UIColor.black
        case "White":
                return UIColor.white
        default:
                return nil
        }
    }
    
    func toDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        guard let date = dateFormatter.date(from: self) else {
            fatalError()
        }
      
        return date
    }

}
