//
//  ConsentDocumentView.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 27/10/21.
//

import SwiftUI

struct ConsentDocumentView: View {
    
    @State private var showPreview = false
    let documentsURL: URL
    
    init(documentURL: URL) {
        self.documentsURL = documentURL
        OTFLog("Opening document at:", self.documentsURL.path)
    }
    
    var body: some View {
        HStack {
            Text("Consent Document")
            Spacer()
            Text("›")
        }.frame(height: 60)
            .contentShape(Rectangle())
            .gesture(TapGesture().onEnded({
                self.showPreview = true
            }))
            .background(DocumentPreviewViewController(self.$showPreview, url: self.documentsURL))
    }
}

struct ConsentDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        let documentsPath = UserDefaults.standard.object(forKey: Constants.UserDefaults.ConsentDocumentURL) as? String
        let url = URL(fileURLWithPath: documentsPath!, isDirectory: false)
        ConsentDocumentView(documentURL: url)
    }
}
