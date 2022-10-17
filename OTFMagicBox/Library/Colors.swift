//
//  Colors.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/20/22.
//

import SwiftUI

struct Colors {
    static let primary = DesignSystem.primaryColor
    static let secondary = DesignSystem.secondaryColor
    static let tertiary = DesignSystem.tertiaryColor
}

private struct DesignSystem {
    static let primaryColor = Color("BluePrimary", bundle: nil)
    static let secondaryColor = Color("RedPrimary", bundle: nil)
    static let tertiaryColor = Color.black.opacity(0.4)
}
