//
//  MedicationSetupCell.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/29/22.
//

import SwiftUI

struct MedicationSetupCell: View {
    @State var cellModel: MedicationSetupCellModel
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(cellModel.title).regular(size: 17).foregroundColor(.gray) + Text(cellModel.titleSufix).regular(size: 17).foregroundColor(.gray.opacity(0.5))
                    Text(cellModel.subtitle).regular(size: 17).foregroundColor(.gray.opacity(0.5))
                }
                Spacer()
            }.padding([.top, .bottom], 12)
            Spacer()
            if !$cellModel.isLastCell.wrappedValue {
                Divider().frame(height: 1)
            }
        }
    }
}

struct MedicationSetupCell_Previews: PreviewProvider {
    static var previews: some View {
        MedicationSetupCell(cellModel: MedicationSetupCellModel(name: "Doppamine", dosage: 2, dosageFrequency: .biweekly))
    }
}
