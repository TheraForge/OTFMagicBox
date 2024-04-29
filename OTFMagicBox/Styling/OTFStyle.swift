//
//  OTFStyle.swift
//  OTFMagicBox
//
//  Created by Tomas Martins on 31/01/24.
//

import Foundation
import SwiftUI
import OTFDesignSystem
import OTFCareKitUI

class OTFStyle: OCKStyler {
    let otfDesignStyle: OTFDesignStyler
    let color: OCKColorStyler
    
    init(from otfDesignStyle: OTFDesignStyler) {
        self.otfDesignStyle = otfDesignStyle
        self.color = OTFThemeColorStyler(from: otfDesignStyle.color)
    }
}

public extension View {
    internal func appStyle(_ style: OTFStyle) -> some View {
        return self
            .environment(\.otfdsStyle, style.otfDesignStyle)
            .environment(\.careKitStyle, style)
    }
}
