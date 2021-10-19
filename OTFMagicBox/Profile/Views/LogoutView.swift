//
//  LogoutView.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 25/09/21.
//

import Foundation
import SwiftUI

struct LogoutView: View {
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {
                OTFTheraforgeNetwork.shared.signOut()
            }, label: {
                 Text("Logout")
                    .font(.system(size: 20, weight: .regular, design: .default))
            })
            
            Spacer()
        }

    }
}

struct LogoutView_Previews: PreviewProvider {
    static var previews: some View {
        LogoutView()
    }
}
