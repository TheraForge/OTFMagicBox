/*
 Copyright (c) 2025, Hippocrates Technologies Sagl. All rights reserved.

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

import Foundation
import OTFUtilities
import OTFTemplateBox

final class ContentViewModel: ObservableObject {

    // MARK: - Publishers

    @Published private(set) var config: AppConfiguration = AppConfigurationLoader.config
    @Published private(set) var isOnboardingCompleted = false
    @Published var isDefaultAPIKey = false

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let logger = OTFLogger.logger()

    // MARK: - Init

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        isOnboardingCompleted = userDefaults.bool(forKey: Constants.Storage.kOnboardingCompleted)
        checkDefaultAPIKey()
        refreshToken()
    }

    // MARK: - Methods

    func setOnboarding(completed: Bool) {
        isOnboardingCompleted = completed
        userDefaults.set(completed, forKey: Constants.Storage.kOnboardingCompleted)
    }

    // MARK: - Private Methods

    private func didCompleteOnBoarding() {
        isOnboardingCompleted = userDefaults.bool(forKey: Constants.Storage.kOnboardingCompleted)
    }

    private func refreshToken() {
        OTFTheraforgeNetwork.shared.refreshToken { response in
            switch response {
            case .success(let data):
                SSEAndSyncManager.shared.subscribeToSSEWith(auth: data.accessToken)
            case .failure(let error):
                guard error.error.statusCode == 410 else { return }
                OTFTheraforgeNetwork.shared.moveToOnboardingView()
            }
        }
    }

    private func checkDefaultAPIKey() {
        guard config.apiKey != AppConfiguration.fallback.apiKey else {
            isDefaultAPIKey = true
            return
        }
        didCompleteOnBoarding()
    }
}
