//
//  FogTimerView.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 9/10/22.
//

import SwiftUI

struct FogTimerView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: FogTimerViewModel
    var body: some View {
        VStack {
            HStack {
                UIImage.loadImage(named: "chevron.left").resizable().renderingMode(.template).foregroundColor(Colors.primary).scaledToFit().frame(width: 16).onTapGesture {
                    presentationMode.wrappedValue.dismiss()
                }
                Text("FoG Timer Setup").medium(size: 24)
                Spacer()
            }.frame(height: 90)
            .padding([.leading, .trailing], 24)
            List {
                Section {
                    HStack {
                        Text("Fog Timer Turned " + ($viewModel.notificationsTurnedOn.wrappedValue ? "On" : "Off")).light(size: 17).foregroundColor(.gray.opacity(0.5))
                        Spacer()
                        Toggle(isOn: $viewModel.notificationsTurnedOn) {
                            
                        }.toggleStyle(SwitchToggleStyle(tint: Colors.primary))
                    }
                }
                if $viewModel.notificationsTurnedOn.wrappedValue {
                    Section {
                        HStack {
                            Text("Assign Time and Date").light(size: 17).foregroundColor(.gray.opacity(0.5))
                            Spacer()
                        }
                        DatePicker("", selection: $viewModel.repetationDate, displayedComponents: [ .hourAndMinute]).datePickerStyle(.wheel)
                    }
                }
            }.listStyle(.insetGrouped)
            Spacer()
            
            HStack(spacing: 16) {
                ZStack {
                    Rectangle().foregroundColor(Colors.primary).cornerRadius(8)
                    Text("Save").medium(size: 24).foregroundColor(.white)
                }.onTapGesture {
                    viewModel.save()
                    presentationMode.wrappedValue.dismiss()
                }
            }.frame(height: 42).padding(16)
        }.navigationTitle("")
        .navigationBarHidden(true)
    }
}

struct FogTimerView_Previews: PreviewProvider {
    static var previews: some View {
        FogTimerView( viewModel: FogTimerViewModel())
    }
}
