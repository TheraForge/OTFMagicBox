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
import OTFCareKitStore
import OTFUtilities

struct UpdateUserProfileView: View {
    @StateObject private var networkManager = OTFNetworkObserver()
    
//    var user: String
    var imageName: String?
    
    var image: UIImage {
        guard let imageName, let image = UIImage(named: imageName) else {
            return UIImage(named: "user_profile")!
        }
        return image
    }
    
    var textColor: Color {
        guard let uiColor = YmlReader().appTheme?.textColor.color else {
            return Color(UIColor.label)
        }
        return Color(uiColor)
    }
    
    @State var showUserProfile = false
    let user: OCKPatient
    let backgroudColor: UIColor
    let tColor: UIColor
    let cellBackgroundColor: UIColor
    @State var fetchFile = Data()
    let headerColor: UIColor
    let buttonColor: UIColor
    let borderColor: UIColor
    let sepratorColor: UIColor
    
    
    @StateObject private var viewModel = UpdateUserViewModel()
    
    var body: some View {
        HStack {
                    ZStack(alignment: .bottomTrailing) {
                        if let retriveImageData = fetchFile.retriveFile(fileName: user.attachments?.Profile?.attachmentID ?? "")  {
                                        let image = viewModel.showProfileImage(user: user, imageData: retriveImageData)
                                        ProfileIcon(image: image)
                                        
                                    } else  {
                                        if !fetchFile.isEmpty {

                                            let image = viewModel.showProfileImage(user: user, imageData: fetchFile)
                                            ProfileIcon(image: image)
                                        } else {
                                            ProfileIcon(image: UIImage(named: ModuleAppYmlReader().profileData?.profileImage ?? "user_profile")!)
                                        }
                                    }
                        NetworkIndicator(status: networkManager.status)
                    }.padding(.trailing)
                    VStack(alignment: .leading) {
                        Text(user.remoteID ?? "")
                            .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                            .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                            .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                            .foregroundColor(textColor)
                        
                        Text("Edit your profile")
                            .font(.footnote)
                            .foregroundColor(textColor)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .font(.footnote.weight(.semibold))
                }
            
            .gesture(TapGesture().onEnded({
                self.showUserProfile.toggle()
            })).sheet(isPresented: $showUserProfile, onDismiss: {
                
            }, content: {
                UpdateUserProfileDetailView(user: user, backgroudColor: backgroudColor, textColor: tColor, cellBackgroundColor: cellBackgroundColor, headerColor: headerColor, buttonColor: buttonColor, borderColor: borderColor, sepratorColor: sepratorColor)
            })
            .background(Color(backgroudColor))
            .onReceive(NotificationCenter.default.publisher(for: .imageUploaded)) { notification in
                if let value = notification.object as? [String: Data] {
                    if let data = value.first?.value{
                        fetchFile = data
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .imageDownloaded)) { notification in
                if let value = notification.object as? [String: Data] {
                    if let data = value.first?.value{
                        fetchFile = data
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .deleteProfile)) { notification in
                fetchFile = Data()
            }
            .onReceive(viewModel.profileImageData) { data in
                fetchFile = data
            }
            .onAppear() {
                if let attachmentID = user.attachments?.Profile?.attachmentID {
                    if fetchFile.retriveFile(fileName: attachmentID) != nil  {} else  {
                        viewModel.downloadFile(attachmentID: attachmentID)
                    }
                }
            }
    }
}


struct NetworkIndicator: View {
    var status: OTFNetworkStatus
    
    var body: some View {
        ZStack {
            Image(systemName: "cloud.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(backgroundColor.opacity(0.85))
                .frame(width: Metrics.NETWORK_INDICATOR_WIDTH)
            
            Image(systemName: accessory)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(UIColor.systemBackground))
                .frame(width: Metrics.NETWORK_INDICATOR_ACCESSORY_WIDTH, height: Metrics.NETWORK_INDICATOR_ACCESSORY_WIDTH)
                .padding(.top, 3)
        }
    }
    
    var backgroundColor: Color {
        switch status {
        case .offline:
            return .yellow
        case .wifi, .cellular:
            return .green
        case .unsatisfied:
            return .gray
        }
    }
    
    var accessory: String {
        switch status {
        case .offline:
            return "antenna.radiowaves.left.and.right.slash"
        case .wifi:
            return "wifi"
        case .cellular:
            return "cellularbars"
        case .unsatisfied:
            return "ellipsis"
        }
    }
}

struct NetworkIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            VStack {
                NetworkIndicator(status: .wifi)
                NetworkIndicator(status: .cellular)
                NetworkIndicator(status: .unsatisfied)
                NetworkIndicator(status: .offline)
            }
        }
    }
}
