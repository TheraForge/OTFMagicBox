/*
 Copyright (c) 2021, Hippocrates Technologies S.r.l.. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributor(s) may
 be used to endorse or promote products derived from this software without specific
 prior written permission. No license is granted to the trademarks of the copyright
 holders even if such marks are included in this software.
 
 4. Commercial redistribution in any form requires an explicit license agreement with the
 copyright holder(s). Please contact support@hippocratestech.com for further information
 regarding licensing.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE.
 */

import SwiftUI

struct ContactsSection: View {
    let cellbackgroundColor: UIColor
    let headerColor: UIColor
    let textColor: UIColor
    var body: some View {
        Section(header: Text(ModuleAppYmlReader().careKitModel?.contactHeader ?? "Contact")
            .font(YmlReader().appTheme?.headerTitleFont.appFont ?? Font.system(size: 17.0))
            .fontWeight(YmlReader().appTheme?.headerTitleWeight.fontWeight)
            .foregroundColor(Color(headerColor))) {
            ForEach(ContactStyle.allCases, id: \.rawValue) { row in
                
                NavigationLink(destination: ContactDestination(style: row)) {
                    Text(String(row.rawValue.capitalized))
                        .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                }
                .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                .foregroundColor(.otfTextColor)
                .listRowBackground(Color.otfCellBackground)
            }
            .listRowBackground(Color(cellbackgroundColor))
            .foregroundColor(Color(textColor))
        }
    }
}

struct ContactsView_Previews: PreviewProvider {
    static var previews: some View {
        ContactsSection(cellbackgroundColor: UIColor(), headerColor: UIColor(), textColor: UIColor())
    }
}

private struct ContactDestination: View {
    
    @Environment(\.storeManager) private var storeManager
    
    let style: ContactStyle
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            AdaptedContactView(style: style, storeManager: storeManager)
        }
        .navigationBarTitle(Text(style.rawValue.capitalized), displayMode: .inline)
    }
}

private enum ContactStyle: String, CaseIterable {
    case simple , detailed
    
    var rawValue: String {
         get {
             switch self {
             case .simple:
                 return ModuleAppYmlReader().careKitModel?.simple ?? ""
             case .detailed:
                 return  ModuleAppYmlReader().careKitModel?.detailed ?? ""
             }
         }
     }
}

import OTFCareKit
import OTFCareKitStore

private struct AdaptedContactView: UIViewControllerRepresentable {
    
    let style: ContactStyle
    let storeManager: OCKSynchronizedStoreManager
    
    func makeUIViewController(context: Context) -> UIViewController {
        let listViewController = OCKListViewController()
        
        let spacer = UIView(frame: .init(origin: .zero, size: .init(width: 0, height: 32)))
        listViewController.appendView(spacer, animated: false)
        
        let viewController: UIViewController?
        switch style {
        case .simple:
            viewController = OCKSimpleContactViewController(contactID: OCKStore.Contacts.matthew.rawValue, storeManager: storeManager)
        case .detailed:
            viewController = OCKDetailedContactViewController(contactID: OCKStore.Contacts.matthew.rawValue, storeManager: storeManager)
        }
        
        viewController.map { listViewController.appendViewController($0, animated: false) }
        return listViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
