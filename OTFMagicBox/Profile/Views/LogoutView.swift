//
//  LogoutView.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 25/09/21.
//

import Foundation
import SwiftUI

struct LogoutView: View {
    @State private var showingOptions = false
    @State private var showingAlert = false
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {
                self.showingOptions.toggle()
            }, label: {
                 Text("Logout")
                    .font(.basicFontStyle)
            })
            .actionSheet(isPresented: $showingOptions) {
                ActionSheet(
                    title: Text("Are you sure?"),
                    buttons: [
                        .destructive(Text("Logout"), action: {
                            OTFTheraforgeNetwork.shared.signOut { result in
                                if case .failure(let error) = result {
                                    print(error.localizedDescription)
                                    self.showingAlert = true
                                }
                            }
                        }),
                        .default(Text("Cancel"))
                    ]
                )
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Failed to logout."), message: nil, dismissButton: .default(Text("Okay")))
            }
            
            Spacer()
        }

    }
}

struct LogoutView_Previews: PreviewProvider {
    static var previews: some View {
        LogoutView()
    }
}
