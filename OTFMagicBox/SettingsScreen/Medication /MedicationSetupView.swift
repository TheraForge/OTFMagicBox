//
//  MedicationSetupView.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/27/22.
//

import SwiftUI

struct MedicationSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MedicationSetupViewModel
    var body: some View {
        VStack {
            HStack {
                UIImage.loadImage(named: "chevron.left").resizable().renderingMode(.template).foregroundColor(Colors.primary).scaledToFit().frame(width: 16).padding([.trailing], 16).onTapGesture {
                    presentationMode.wrappedValue.dismiss()
                }
                Text("My Medication Setup").medium(size: 24)
                Spacer()
                NavigationLink(destination: MedicationSetupEntryView(viewModel: MedicationSetupEntryViewModel(isEditing: false, cellModel: nil), isEditOn: true)) {
                    UIImage.loadImage(named: "plus.circle")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Colors.primary)
                        .scaledToFit()
                        .frame(width: 36, height: 28)
                }
            }
            .frame(height: 90)
            .padding([.leading, .trailing], 24)
            
            List {
                ForEach(viewModel.cells) { cell in
                    NavigationLink(destination: MedicationSetupEntryView(viewModel: MedicationSetupEntryViewModel(isEditing: true, cellModel: cell), isEditOn: false)) {
                        MedicationSetupCell(cellModel: cell)
                    }
                }
            }
            
        }.onAppear {
            viewModel.loadItems()
            UITableView.appearance().separatorColor = .clear
        }
    }
}

struct MedicationSetupView_Previews: PreviewProvider {
    static var previews: some View {
        MedicationSetupView(viewModel: MedicationSetupViewModel())
    }
}
