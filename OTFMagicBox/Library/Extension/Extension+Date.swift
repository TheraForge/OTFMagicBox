//
//  Extension+Date.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 28/10/21.
//

import Foundation

extension Date {
    
    var toString: String {
        // Create Date Formatter
        let dateFormatter = DateFormatter()

        // Set Date Format
        dateFormatter.dateFormat = "MM/dd/YYYY"

        // Convert Date to String
        return dateFormatter.string(from: self)
    }
}
