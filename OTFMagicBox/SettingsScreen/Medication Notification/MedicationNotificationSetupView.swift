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
    var body: some View {
        VStack {
            HStack {
                UIImage.loadImage(named: "chevron.left").resizable().renderingMode(.template).foregroundColor(Colors.primary).scaledToFit().frame(width: 16).padding([.trailing], 16).onTapGesture {
                    presentationMode.wrappedValue.dismiss()
                }
                Text("Medication Notification").medium(size: 24)
                Spacer()
                NavigationLink(destination: MedicationNotificationSetupEntryView(viewModel: MedicationNotificationSetupEntryViewModel(isEditing: false, cellModel: nil), isEditOn: true)) {
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
                    NavigationLink(destination: MedicationNotificationSetupEntryView(viewModel: MedicationNotificationSetupEntryViewModel(isEditing: true, cellModel: cell), isEditOn: false)) {
                        MedicationSetupCell(cellModel: cell)
                    }
                }
            }
            
        }.onAppear {
            viewModel.loadItems()
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

