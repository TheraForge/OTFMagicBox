/*
 Copyright (c) 2024, Hippocrates Technologies Sagl. All rights reserved.

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
import OTFCareKitUI
import OTFCareKitStore

struct MainView: View {

    let color: Color

    init() {
        self.color = Color(YmlReader().appStyle.buttonTextColor.color ??
                           YmlReader().primaryColor)
        OTFTheraforgeNetwork.shared.refreshToken { response in
            switch response {
            case .success(let data):
                SSEAndSyncManager.shared.subscribeToSSEWith(auth: data.accessToken)
            case .failure(let error):
                if error.error.statusCode == 410 {
                    OTFTheraforgeNetwork.shared.moveToOnboardingView()
                }
            }
        }
        
    }

    var body: some View {
        TabView {
            if YmlReader().useCareKit {
                ScheduleViewControllerRepresentable().tabItem {
                    UIImage.loadImage(named: "tab_schedule").renderingMode(.template)
                    Text("Tasks")
                        .font(Font.otfAppFont)
                        .fontWeight(Font.otfFontWeight)
                }
                .ignoresSafeArea(.all)
                
                NavigationView {
                    ContactsViewController(storeManager: CareKitStoreManager.shared.synchronizedStoreManager)
                        .navigationBarTitle(Text("Care Team"), displayMode: .inline)
                }
                .tabItem {
                    UIImage.loadImage(named: "tab_care").renderingMode(.template)
                    Text("Contacts")
                        .font(Font.otfAppFont)
                        .fontWeight(Font.otfFontWeight)
                }
            }

            if YmlReader().showCheckupScreen {
                NavigationView {
                    CheckUpView().navigationBarTitle(Text(Constants.CustomiseStrings.checkUp), displayMode: .inline)
                }.tabItem {
                    UIImage.loadImage(named: "tab_tasks").renderingMode(.template)
                    Text(Constants.CustomiseStrings.checkUp)
                         .font(Font.otfAppFont)
                         .fontWeight(Font.otfFontWeight)
                }
            }

            if YmlReader().showStaticUIScreen {
                NavigationView {
                    StaticUI().navigationBarTitle(Text("Sample Views"), displayMode: .inline)
                }.tabItem {
                    Image(systemName: "uiwindow.split.2x1")
                    Text("UI")
                        .font(Font.otfAppFont)
                        .fontWeight(Font.otfFontWeight)
                }
            }

            ProfileUIView().navigationBarTitle(Text(ModuleAppYmlReader().profileData?.title ?? Constants.CustomiseStrings.profile), displayMode: .inline)
                .tabItem {
                    UIImage.loadImage(named: "tab_profile").renderingMode(.template)
                    Text(Constants.CustomiseStrings.profile)
                        .font(Font.otfAppFont)
                        .fontWeight(Font.otfFontWeight)
                }
        }
        .accentColor(self.color)
    }
}
