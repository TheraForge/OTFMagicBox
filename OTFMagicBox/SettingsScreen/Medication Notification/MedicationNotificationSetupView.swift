//
//  MedicationNotificationSetupView.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 9/4/22.
//

import SwiftUI

struct MedicationNotificationSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MedicationNotificationSetupViewModel
    @State private var isNavigationActive: Bool = false
    var body: some View {
        VStack {
            HStack {
                UIImage.loadImage(named: "chevron.left").resizable().renderingMode(.template).foregroundColor(Colors.primary).scaledToFit().frame(width: 16).padding([.trailing], 16).onTapGesture {
                    presentationMode.wrappedValue.dismiss()
                }
                Text("Medication Notification").medium(size: 24)
                Spacer()
                NavigationLink(destination: MedicationNotificationSetupEntryView(viewModel: MedicationNotificationSetupEntryViewModel(isEditing: false, cellModel: nil, medications: viewModel.medications), isEditOn: true)) {
                    UIImage.loadImage(named: "plus.circle")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Colors.primary)
                        .scaledToFit()
                        .frame(width: 36, height: 28)
                }.disabled($viewModel.isNavigationEnabled.wrappedValue)
            }
            .frame(height: 90)
            .padding([.leading, .trailing], 24)
            
            List {
                ForEach(viewModel.cells) { cell in
                    NavigationLink(destination: MedicationNotificationSetupEntryView(viewModel: MedicationNotificationSetupEntryViewModel(isEditing: true, cellModel: cell, medications: viewModel.medications), isEditOn: false)) {
                        MedicationSetupCell(cellModel: cell)
                    }
                }
            }
            
        }.onAppear {
            viewModel.loadItems()
            UITableViewCell.appearance().selectionStyle = .none
            UITableView.appearance().separatorColor = .clear
        }.navigationTitle("")
        .navigationBarHidden(true)
    }
}

struct MedicationNotificationSetupView_Previews: PreviewProvider {
    static var previews: some View {
        MedicationNotificationSetupView(viewModel: MedicationNotificationSetupViewModel())
    }
}

