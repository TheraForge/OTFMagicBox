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
import OTFCloudClientAPI
import OTFUtilities
import Combine
import OTFTemplateBox

final class ChangePasswordViewModel: ObservableObject {

    private enum FileConstants {
        static let fileName = "ChangePasswordConfiguration"
    }

    // MARK: Publishers

    @Published var showFailureAlert = false
    @Published var errorMessage = String()
    @Published var oldPassword: String = ""
    @Published var newPassword: String = ""
    @Published var email: String

    @Published private(set) var config: ChangePasswordConfiguration = .fallback

    // MARK: Properties

    var error: ForgeError?
    var viewDismissModePublisher = PassthroughSubject<Bool, Never>()

    private var disposables = Set<AnyCancellable>()
    private let logger = OTFLogger.logger()
    private let decoder: OTFYAMLDecoding

    private var shouldDismissView = false {
        didSet {
            viewDismissModePublisher.send(shouldDismissView)
        }
    }

    // MARK: Init

    init(email: String, decoder: OTFYAMLDecoding = OTFYAMLDecoderEngine()) {
        self.email = email
        self.decoder = decoder
        loadConfiguration()
    }

    // MARK: Methods

    func changePassword() {
        OTFTheraforgeNetwork.shared.changePassword(email: email, oldPassword: oldPassword, newPassword: newPassword)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                switch response {
                case .failure(let error):
                    self?.logger.error("error in change password request -> \(error.error.message)")
                    self?.errorMessage = error.error.message
                    self?.showFailureAlert = true
                default: break
                }
            } receiveValue: { [weak self] data in
                self?.shouldDismissView = true
                self?.logger.info("error in change password request -> \(data.message)")
            }
            .store(in: &disposables)
    }

    // MARK: - Private Methods

    private func loadConfiguration() {
        do {
            config = try decoder.decode(FileConstants.fileName, as: ChangePasswordConfiguration.self)
        } catch {
            OTFLogger.logger().error("Profile config load error: \(error)")
            config = .fallback
        }
    }
}
