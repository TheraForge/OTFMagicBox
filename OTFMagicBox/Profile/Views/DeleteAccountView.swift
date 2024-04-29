//
//  DeleteAccountView.swift
//  OTFMagicBox
//
//  Created by Arsalan Raza on 25/05/2022.
//

import Foundation
import SwiftUI
import OTFCareKitStore
import OTFUtilities

struct DeleteAccountView: View {
    @StateObject private var viewModel = DeleteAccountViewModel()
    @State private(set) var user: OCKPatient?

    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                viewModel.showingOptions.toggle()
            }, label: {
                Text(Constants.CustomiseStrings.deleteAccount)
                    .font(.basicFontStyle)
                    .foregroundColor(Color.red)
                    .font(Font.otfAppFont)
                    .fontWeight(Font.otfFontWeight)
            })
            .actionSheet(isPresented: $viewModel.showingOptions) {
                ActionSheet(
                    title: Text(Constants.CustomiseStrings.removeInformation)
                        .font(Font.otfAppFont)
                        .fontWeight(Font.otfFontWeight),
                    buttons: [
                        .destructive(Text(Constants.CustomiseStrings.deleteAccount), action: {
                            viewModel.deleteUserAccount(userId: user?.id ?? "")
                        }),
                        .cancel(Text(Constants.CustomiseStrings.cancel)
                                    .fontWeight(Font.otfFontWeight)
                                    .font(Font.otfAppFont))
                    ]
                )
            }
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(title: Text(Constants.CustomiseStrings.faliedToDeleteAccount)
                        .font(Font.otfAppFont)
                        .fontWeight(Font.otfFontWeight), message: nil, dismissButton: .default(Text(Constants.CustomiseStrings.okay)))
            }

            Spacer()
        }

    }
}

struct DeleteAccountView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteAccountView(user: nil)
    }
}
