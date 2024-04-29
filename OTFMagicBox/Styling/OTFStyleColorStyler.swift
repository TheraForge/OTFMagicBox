//
//  OTFStyleColorStyler.swift
//  OTFMagicBox
//
//  Created by Tomas Martins on 06/02/24.
//

import Foundation
import OTFDesignSystem
import OTFCareKitUI

class OTFThemeColorStyler: OCKColorStyler {
    let otfDesignColor: OTFDesignStylerColor
    
    init(from otfDesignColor: OTFDesignStylerColor) {
        self.otfDesignColor = otfDesignColor
    }
    
    var label: UIColor {
        return UIColor(otfDesignColor.label)
    }
    
    var secondaryLabel: UIColor {
        return UIColor(otfDesignColor.secondaryLabel)
    }
    
    var tertiaryLabel: UIColor {
        return UIColor(otfDesignColor.tertiaryLabel)
    }
    
    var separator: UIColor {
        return UIColor(otfDesignColor.separator)
    }
    
    var customFill: UIColor {
        return UIColor(otfDesignColor.customFill)
    }
    
    var secondaryCustomFill: UIColor {
        return UIColor(otfDesignColor.secondaryCustomFill)
    }
    
    var tertiaryCustomFill: UIColor {
        return UIColor(otfDesignColor.tertiaryCustomFill)
    }
    
    var quaternaryCustomFill: UIColor {
        return UIColor(otfDesignColor.quaternaryCustomFill)
    }
    
    var customBlue: UIColor {
        return UIColor(otfDesignColor.customBlue)
    }
    
    var customGray: UIColor {
        return UIColor(otfDesignColor.customGray)
    }
    
    var customGray2: UIColor {
        return UIColor(otfDesignColor.customGray2)
    }
    
    var customGray3: UIColor {
        return UIColor(otfDesignColor.customGray3)
    }
    
    var customGray4: UIColor {
        return UIColor(otfDesignColor.customGray4)
    }
    
    var customGray5: UIColor {
        return UIColor(otfDesignColor.customGray5)
    }
    
    var white: UIColor {
        return UIColor.white
    }
    
    var black: UIColor {
        return UIColor.black
    }
    
    var clear: UIColor {
        return UIColor.clear
    }
    
    var customBackground: UIColor {
        return UIColor(otfDesignColor.customBackground)
    }
    
    var secondaryCustomBackground: UIColor {
        return UIColor(otfDesignColor.secondaryCustomBackground)
    }
    
    var customGroupedBackground: UIColor {
        return UIColor(otfDesignColor.customGroupedBackground)
    }
    
    var secondaryCustomGroupedBackground: UIColor {
        return UIColor(otfDesignColor.secondaryCustomGroupedBackground)
    }
    
    var tertiaryCustomGroupedBackground: UIColor {
        return UIColor(otfDesignColor.tertiaryCustomGroupedBackground)
    }
}

