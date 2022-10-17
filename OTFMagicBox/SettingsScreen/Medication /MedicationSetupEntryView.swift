//
//  MedicationSetupEntryView.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/29/22.
//

import SwiftUI

struct MedicationSetupEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MedicationSetupEntryViewModel
    @State var isEditOn: Bool
    var body: some View {
        VStack {
            HStack {
                UIImage.loadImage(named: "chevron.left").resizable().renderingMode(.template).foregroundColor(Colors.primary).scaledToFit().frame(width: 16).padding([.leading,.trailing], 16).onTapGesture {
                    presentationMode.wrappedValue.dismiss()
                }
                Text("My Medication Entry").medium(size: 24)
                Spacer()
                if viewModel.isEditing {
                    Text(isEditOn ? "Done" : "Edit").medium(size: 22).foregroundColor(Colors.primary).padding(.trailing, 16).onTapGesture {
                        isEditOn.toggle()
                    }
                }
            }.frame(height: 80)
            List {
                Section {
                    HStack {
                        Text("Name").light(size: 17).foregroundColor(.gray.opacity(0.5))
                        Spacer()
                        if $isEditOn.wrappedValue {
                            TextField(($isEditOn.wrappedValue ? "Medication Name" : viewModel.cellModel.name), text: $viewModel.cellModel.name).disabled(!isEditOn)
                        } else {
                            Text($viewModel.cellModel.wrappedValue.title).regular(size: 18)
                        }
                    }
                }
                Section {
                    HStack {
                        TextField(("Description"), text: $viewModel.cellModel.description).disabled(!isEditOn)
                        Spacer()
                    }
                }
                
                Section {
                    VStack {
                        HStack {
                            Text($isEditOn.wrappedValue ? "Assign Dosage" : "Dosage")
                                .light(size: 17)
                                .foregroundColor(.gray.opacity(0.5))
                                .frame(minHeight: 74)
                            Spacer()
                            if !$isEditOn.wrappedValue {
                                Text(String($viewModel.cellModel.dosage.wrappedValue))
                                    .regular(size: 17)
                                    .frame(minHeight: 74)
                                    .padding(.trailing,16)
                                Text(viewModel.cellModel.dosageFrequency.title)
                                    .regular(size: 17)
                                    .frame(minHeight: 74)
                            }
                        }
                        if $isEditOn.wrappedValue {
                            Divider()
                            HStack {
                                Picker("", selection: $viewModel.cellModel.dosage) {
                                    ForEach(0..<10, id: \.self) { dose in
                                        Text(String(dose)).tag(dose)
                                    }
                                }.pickerStyle(.wheel).frame(width: (UIScreen.screenWidth-80)/2, height: 150)
                                    .clipped()
                                Picker("", selection: $viewModel.cellModel.dosageFrequency) {
                                    ForEach(DosageFrequency.allCases, id: \.rawValue) { freq in
                                        Text(freq.title).tag(freq)
                                    }
                                }.pickerStyle(.wheel).frame(width: (UIScreen.screenWidth-80)/2, height: 150)
                                    .clipped()
                            }
                        }
                    }
                }
            }.listStyle(.insetGrouped)
            Spacer()
            
            HStack(spacing: 16) {
                if !$viewModel.isEditing.wrappedValue {
                    ZStack {
                        Rectangle().foregroundColor(Colors.primary).cornerRadius(8)
                        Text("Done").medium(size: 24).foregroundColor(.white)
                    }.onTapGesture {
                        viewModel.save()
                        presentationMode.wrappedValue.dismiss()
                    }
                } else if $isEditOn.wrappedValue {
                    ZStack {
                        Rectangle().foregroundColor(Colors.primary).cornerRadius(8)
                        Text("Cancel").medium(size: 24).foregroundColor(.white)
                    }.onTapGesture {
                        isEditOn.toggle()
                    }
                    ZStack {
                        Rectangle().foregroundColor(Colors.primary).cornerRadius(8)
                        Text("Delete").medium(size: 24).foregroundColor(Colors.tertiary)
                    }.onTapGesture {
                        isEditOn.toggle()
                    }
                }
            }.frame(height: 42).padding(16)
        }.navigationTitle("")
            .navigationBarHidden(true)
    }
}

struct MedicationSetupEntryView_Previews: PreviewProvider {
    static var previews: some View {
        MedicationSetupEntryView(viewModel: MedicationSetupEntryViewModel(isEditing: false, cellModel: MedicationSetupCellModel(name: "Dopamine", dosage: 1, dosageFrequency: .daily)), isEditOn: false)
    }
}
