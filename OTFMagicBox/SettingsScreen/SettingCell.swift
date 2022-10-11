//
//  SettingCell.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/24/22.
//

import SwiftUI

struct SettingCell: View {
    @State var settingCell: SettingsCellItem
    var body: some View {
        Spacer()
        HStack {
            VStack {
                Text(settingCell.title).light(size: 17)
            }
            Spacer()
            VStack {
                UIImage.loadImage(named: "chevron.right")
            }
        }
        Spacer()
        if !settingCell.isLastCell {
            Divider()
        }
    }
}

struct SettingCell_Previews: PreviewProvider {
    static var previews: some View {
        SettingCell(settingCell: SettingsCellItem(title: "Medication Setup", navigationDestination: .medicationSetup))
    }
}
