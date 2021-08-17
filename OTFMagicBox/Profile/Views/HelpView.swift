//
//  HelpView.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 14.05.21.
//

import SwiftUI

struct HelpView: View {
    var site = ""
    
    init(site: String) {
        self.site = site
    }
    
    var body: some View {
        HStack {
            Text("Help")
            Spacer()
            Text("›")
        }.frame(height: 70).contentShape(Rectangle())
            .gesture(TapGesture().onEnded({
                if let url = URL(string: self.site) {
                UIApplication.shared.open(url)
            }
        }))
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView(site: "")
    }
}
