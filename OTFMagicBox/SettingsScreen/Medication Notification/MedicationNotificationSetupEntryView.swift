//
//  MedicationNotificationSetupEntryView.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 9/5/22.
//

import SwiftUI

struct MedicationNotificationSetupEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MedicationNotificationSetupEntryViewModel
    @State var isEditOn: Bool
    var body: some View {
        VStack {
            HStack {
                UIImage.loadImage(named: "chevron.left").resizable().renderingMode(.template).foregroundColor(Colors.primary).scaledToFit().frame(width: 16).padding([.leading,.trailing], 16).onTapGesture {
                    presentationMode.wrappedValue.dismiss()
                }
                Text("Medication Notification").medium(size: 24)
                Spacer()
                if viewModel.isEditing {
                    Text(isEditOn ? "Done" : "Edit").medium(size: 22).foregroundColor(Colors.primary).padding(.trailing, 16).onTapGesture {
                        if isEditOn {
                            viewModel.save()
                        }
                        isEditOn.toggle()
                    }
                }
            }.frame(height: 80)
            List {
                Section {
                    VStack {
                        HStack {
                            Text("Which Medication?").light(size: 17).foregroundColor(.gray.opacity(0.5))
                            Spacer()
                            if !$isEditOn.wrappedValue {
                                Text($viewModel.cellModel.wrappedValue.name).regular(size: 18)
                            }
                        }
                        if $isEditOn.wrappedValue {
                            Divider()
                            HStack {
                                Picker("", selection: $viewModel.cellModel.name) {
                                    ForEach(viewModel.medics, id: \.self) { med in
                                        Text(med).tag(med)
                                    }
                                }.pickerStyle(.wheel).frame(height: 100)
                                    .clipped()
                            }
                        }
                    }
                }
                Section {
                    VStack {
                        HStack {
                            Text($isEditOn.wrappedValue ? "Assign Date & Time" : "Date & Time").light(size: 17).foregroundColor(.gray.opacity(0.5))
                            Spacer()
                            if !$isEditOn.wrappedValue {
                                Text(String($viewModel.cellModel.wrappedValue.hours)).regular(size: 18)
                                Text($viewModel.cellModel.wrappedValue.dosageFrequency.title).regular(size: 18).padding([.leading, .trailing], 16)
                            }
                        }
                        if $isEditOn.wrappedValue {
                            Divider()
                            HStack {
                                Picker("", selection: $viewModel.cellModel.hours) {
                                    ForEach(0..<24, id: \.self) { hour in
                                        Text(String(hour)).tag(hour)
                                    }
                                }.pickerStyle(.wheel)
                                    .frame(width: (UIScreen.screenWidth-80)/2, height: 150)
                                .clipped()
                                Spacer()
                                Picker("", selection: $viewModel.cellModel.notificationFrequency) {
                                    ForEach(DosageFrequency.allCases, id: \.rawValue) { freq in
                                        Text(freq.title).tag(freq)
                                    }
                                }.pickerStyle(.wheel)
                                .frame(width: (UIScreen.screenWidth-80)/2, height: 150)
                                .clipped()
                            }
                        }
                    }
                }
                
                Section {
                    VStack {
                        HStack {
                            Text("Repeat Until")
                                .light(size: 17)
                                .foregroundColor(.gray.opacity(0.5))
                                .frame(minHeight: 74)
                            Spacer()
                            if !$isEditOn.wrappedValue {
                                Text($viewModel.cellModel.wrappedValue.endDate.toString)
                                    .regular(size: 17)
                                    .frame(minHeight: 74)
                                    .padding(.trailing,16)
                            }
                        }
                        if $isEditOn.wrappedValue {
                            Divider()
                            DatePicker("", selection: $viewModel.cellModel.endDate, displayedComponents: [.date]).datePickerStyle(.wheel)
                            
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
                        viewModel.deleteSelected()
                        presentationMode.wrappedValue.dismiss()
                        isEditOn.toggle()
                    }
                }
            }.frame(height: 42).padding(16)
        }.navigationTitle("")
            .navigationBarHidden(true)
    }
}

struct MedicationNotificationSetupEntryView_Previews: PreviewProvider {
    static var previews: some View {
        MedicationNotificationSetupEntryView(viewModel: MedicationNotificationSetupEntryViewModel(isEditing: false, cellModel: nil), isEditOn: true)
    }
}
