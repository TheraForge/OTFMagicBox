//
//  UpdateUserProfileView.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 25/10/21.
//

import SwiftUI
import OTFCareKitStore

struct UpdateUserProfileView: View {
    
    @State var showUserProfile = false
    let user: OCKPatient
    
    var body: some View {
        VStack {
            Image.avatar
                .iconStyle()
                .frame(width: 40, height: 40, alignment: .center)
             
            HStack {
                Text(user.remoteID ?? "")
                Spacer()
                Text("›")
            }
        }.frame(height: 80).contentShape(Rectangle())
        .gesture(TapGesture().onEnded({
            self.showUserProfile.toggle()
        })).sheet(isPresented: $showUserProfile, onDismiss: {
            
        }, content: {
            UpdateUserProfileDetailView(user: user)
        })
    }
}

/*
struct UpdateUserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let user = CareKitManager.shared.cloudantStore?.getThisPatient(<#T##completion: OCKResultClosure<OCKPatient>##OCKResultClosure<OCKPatient>##(Result<OCKPatient, OCKStoreError>) -> Void#>)
        UpdateUserProfileView(user: user!)
    }
}
 */
