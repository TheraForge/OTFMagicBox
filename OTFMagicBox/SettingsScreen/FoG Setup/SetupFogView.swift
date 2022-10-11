//
//  SetupFogView.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 9/10/22.
//

import SwiftUI

struct SetupFogView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: SetupFogViewModel
    
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
                        Text("Add Custom Recording").regular(size: 17).foregroundColor(.gray)
                        Spacer()
                    }
                }.onTapGesture {
                    _ = print("Add custom Recording")
                }
                Section {
                    HStack {
                        Text("Add Custom Music").regular(size: 17).foregroundColor(.gray)
                        Spacer()
                    }
                }.onTapGesture {
                    _ = print("Add custom Music")
                }
            }.listStyle(.insetGrouped)
            Spacer()
            HStack(spacing: 16) {
                ZStack {
                    Rectangle().foregroundColor(Colors.primary).cornerRadius(8)
                    Text("Reset").medium(size: 24).foregroundColor(Colors.secondary)
                }.onTapGesture {
                    viewModel.askForReset()
                }
            }.frame(height: 42).padding(16)
        }.alert(item: $viewModel.alertToPresent) { alertModel in
            Alert(alertModel: alertModel)
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .onReceive(viewModel.viewDismissalModePublisher) { shouldPop in
            if shouldPop {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
        Spacer()
    }
}

struct SetupFogView_Previews: PreviewProvider {
    static var previews: some View {
        SetupFogView(viewModel: SetupFogViewModel())
    }
}
