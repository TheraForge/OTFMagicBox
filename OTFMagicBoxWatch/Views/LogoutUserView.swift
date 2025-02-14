//
//  LogoutUserView.swift
//  OTFMagicBoxWatch
//
//  Created by Waqas Khadim on 25/07/2024.
//

import SwiftUI

struct LogoutUserView: View {
    var body: some View {
        ZStack {
            Image("background")
                .resizable()
            VStack(alignment: .center) {
                Text(Constants.logout)
                    .font(.system(size: 14))
                    .fontWeight(.bold)
                    .padding(.horizontal, 27)
                    .multilineTextAlignment(.center)
                    
            }
        }.edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    LogoutUserView()
}
