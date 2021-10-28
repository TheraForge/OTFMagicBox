//
//  ConsentDocumentView.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 27/10/21.
//

import SwiftUI

struct ConsentDocumentView: View {
    
    @State private var showPreview = false
    var documentsURL: URL? = nil
    
    init() {
        if let documentsPath = UserDefaults.standard.object(forKey: Constants.UserDefaults.ConsentDocumentURL) as? String {
            self.documentsURL = URL(fileURLWithPath: documentsPath, isDirectory: false)
            OTFLog("Opening document at:", self.documentsURL!.path)
        } else {
            OTFLog("No consent document to open at path", self.documentsURL!.path)
        }
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
        ConsentDocumentView()
    }
}
