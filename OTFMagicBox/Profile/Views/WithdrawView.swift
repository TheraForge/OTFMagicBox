//
//  WithdrawView.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 08/07/21.
//

import SwiftUI

struct WithdrawView: View {
    @State var showWithdraw = false
    
    var body: some View {
        HStack {
            Text("Withdraw from Study")
            Spacer()
            Text("›")
        }.frame(height: 60)
        .contentShape(Rectangle())
        .gesture(TapGesture().onEnded({
            self.showWithdraw.toggle()
        })).sheet(isPresented: $showWithdraw, onDismiss: {
            
        }, content: {
            WithdrawalViewController()
        })
    }
}

struct WithdrawView_Previews: PreviewProvider {
    static var previews: some View {
        WithdrawView()
    }
}
