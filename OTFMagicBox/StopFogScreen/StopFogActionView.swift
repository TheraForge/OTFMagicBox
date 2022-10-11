//
//  StopFogActionView.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/27/22.
//

import SwiftUI

struct StopFogActionView: View {
    @ObservedObject var viewModel: StopFogActionViewModel
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack(spacing: 50) {
            $viewModel.image.wrappedValue.resizable().frame(width: 120, height: 120).padding(.top, 50)
            
            Text("Keep Calm!").medium(size: 40)
            
            Text("Your favorite rhythm is on!").light(size: 24)
            
            Spacer()
            HStack {
                VStack(spacing: 2) {
                    Image("PlayButtonImage")
                    Text("Next Please").light(size: 17)
                }
                .onTapGesture {
                    viewModel.nextAction()
                }
            }
            Spacer()
        
            ZStack {
            Rectangle()
                    .background(Colors.primary)
                    .cornerRadius(8)
                    .foregroundColor(Colors.primary)
                Text("FoG is Gone!").medium(size: 17).foregroundColor(.white)
            }.onTapGesture {
                viewModel.stopActions()
                presentationMode.wrappedValue.dismiss()
            }
            .frame(height: 48)
            .padding([.leading, .trailing, .bottom], 16)
        }
    }
}

struct StopFogActionView_Previews: PreviewProvider {
    static var previews: some View {
        StopFogActionView(viewModel: StopFogActionViewModel(actionList: []))
    }
}
