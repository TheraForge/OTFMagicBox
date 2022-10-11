//
//  SurveyReminderSetupView.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 9/5/22.
//

import SwiftUI

struct SurveyReminderSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: SurveyReminderSetupViewModel
    var body: some View {
        VStack {
            HStack {
                UIImage.loadImage(named: "chevron.left").resizable().renderingMode(.template).foregroundColor(Colors.primary).scaledToFit().frame(width: 16).padding([.leading,.trailing], 16).onTapGesture {
                    presentationMode.wrappedValue.dismiss()
                }
                Text("Survey Reminder Setup").medium(size: 24)
                Spacer()
            }.frame(height: 80)
            List {
                Section {
                    HStack {
                        Text("Notifications Turned " + ($viewModel.cellModel.wrappedValue.notificationsTurnedOn ? "On" : "Off")).light(size: 17).foregroundColor(.gray.opacity(0.5))
                        Spacer()
                        Toggle(isOn: $viewModel.cellModel.notificationsTurnedOn) {
                            
                        }.toggleStyle(SwitchToggleStyle(tint: Colors.primary))
                    }
                }
                Section {
                    HStack {
                        Text("Assign Time and Date").light(size: 17).foregroundColor(.gray.opacity(0.5))
                        Spacer()
                    }
                    DatePicker("", selection: $viewModel.cellModel.repetationDate, displayedComponents: [.date, .hourAndMinute]).datePickerStyle(.wheel)
                }
                
                Section {
                    VStack {
                        HStack {
                            Text("Repeat")
                                .light(size: 17)
                                .foregroundColor(.gray.opacity(0.5))
                                .frame(minHeight: 74)
                            Spacer()
                        }
                        Divider()
                        Picker("", selection: $viewModel.cellModel.repetation) {
                            ForEach(SurveyRepetation.allCases, id: \.rawValue) { freq in
                                Text(freq.title).tag(freq)
                            }
                        }.pickerStyle(.wheel).frame(height: 100)
                            .clipped()
                    }
                }
            }.listStyle(.insetGrouped)
            Spacer()
            
            HStack(spacing: 16) {
                ZStack {
                    Rectangle().foregroundColor(Colors.primary).cornerRadius(8)
                    Text("Done").medium(size: 24).foregroundColor(.white)
                }.onTapGesture {
                    viewModel.save()
                    presentationMode.wrappedValue.dismiss()
                }
            }.frame(height: 42).padding(16)
        }.navigationTitle("")
            .navigationBarHidden(true)
    }
}
struct SurveyReminderSetupView_Previews: PreviewProvider {
    static var previews: some View {
        SurveyReminderSetupView(viewModel: SurveyReminderSetupViewModel())
    }
}
