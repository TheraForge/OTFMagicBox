//
//  DeleteAccountView.swift
//  OTFMagicBox
//
//  Created by Arsalan Raza on 25/05/2022.
//

import Foundation
import SwiftUI
import OTFCareKitStore

struct DeleteAccountView: View {
    @State private var showingOptions = false
    @State private var showingAlert = false
    @State private(set) var user: OCKPatient?
    let textColor: UIColor
    var deleteUserHandler: ((Bool?) -> Void)?

    
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                self.showingOptions.toggle()
            }, label: {
                Text("Delete Account")
                    .font(.basicFontStyle)
                    .foregroundColor(Color.red)
                    .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                    .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
            })
            .actionSheet(isPresented: $showingOptions) {
                ActionSheet(
                    title: Text("Are you sure? This will remove all your information.")
                        .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                        .fontWeight(YmlReader().appTheme?.textWeight.fontWeight),
                    buttons: [
                        .destructive(Text("Delete account"), action: {
                            deleteUserHandler?(false)
                            OTFTheraforgeNetwork.shared.deleteUser(userId: user?.id ?? "") { result in
                                switch result {
                                case .failure(let error):
                                    print(error.localizedDescription)
                                    self.showingAlert = true
                                case .success:
                                    deleteUserHandler?(true)
                                }
                            }
                        }),
                        .cancel(Text("Cancel")
                            .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                            .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0)))
                    ]
                )
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Failed to logout.")
                    .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                    .fontWeight(YmlReader().appTheme?.textWeight.fontWeight), message: nil, dismissButton: .default(Text("Okay")))
            }
            
            Spacer()
        }
        
    }
}

struct DeleteAccountView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteAccountView(user: nil, textColor: UIColor())
    }
}
