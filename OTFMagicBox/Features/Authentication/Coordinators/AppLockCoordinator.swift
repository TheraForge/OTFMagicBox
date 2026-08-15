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

import UIKit
import OTFUtilities
import OTFResearchKit

struct AppLockFailedAttemptCounter {
    let maxFailedAttempts: Int
    private(set) var failedAttempts = 0

    init(maxFailedAttempts: Int = 3) {
        self.maxFailedAttempts = maxFailedAttempts
    }

    mutating func recordFailure() -> Bool {
        failedAttempts += 1
        guard failedAttempts >= maxFailedAttempts else {
            return false
        }

        failedAttempts = 0
        return true
    }

    mutating func recordSuccess() {
        failedAttempts = 0
    }
}

final class AppLockCoordinator: NSObject, ORKPasscodeDelegate {
    static let shared = AppLockCoordinator()

    private enum Constants {
        static let maxFailedAttempts = 3
    }

    private var failedAttemptCounter = AppLockFailedAttemptCounter(maxFailedAttempts: Constants.maxFailedAttempts)
    private let logger = OTFLogger.logger()

    func presentIfNeeded(from presenter: UIViewController? = UIApplication.shared.topMostViewController()) {
        let auth = AuthConfigurationLoader.auth

        guard auth.passcodeEnabled, ORKPasscodeViewController.isPasscodeStoredInKeychain(), !isPasscodeAlreadyPresented(on: presenter) else { return }
        let controller = ORKPasscodeViewController.passcodeAuthenticationViewController(withText: auth.passcodePrompt.localized, delegate: self)

        controller.view.backgroundColor = .systemGroupedBackground
        controller.modalPresentationStyle = .fullScreen

        DispatchQueue.main.async {
            presenter?.present(controller, animated: true)
        }
    }

    // MARK: - ORKPasscodeDelegate

    func passcodeViewControllerDidFinish(withSuccess viewController: UIViewController) {
        failedAttemptCounter.recordSuccess()
        viewController.dismiss(animated: true)
    }

    func passcodeViewControllerDidFailAuthentication(_ viewController: UIViewController) {
        let failedAttemptCount = failedAttemptCounter.failedAttempts + 1
        let shouldForceLogout = failedAttemptCounter.recordFailure()
        logger.warning(
            "Passcode auth failed (\(failedAttemptCount)/\(Constants.maxFailedAttempts))"
        )

        guard shouldForceLogout else { return }
        if ORKPasscodeViewController.isPasscodeStoredInKeychain() {
            ORKPasscodeViewController.removePasscodeFromKeychain()
        }

        viewController.dismiss(animated: true) {
            ProfileViewModel.forceLogoutDueToFailedPasscode()
        }
    }

    private func isPasscodeAlreadyPresented(on presenter: UIViewController?) -> Bool {
        guard let presenter = presenter?.presentedViewController else { return false }
        if presenter is ORKPasscodeViewController {
            return true
        }
        if let nav = presenter as? UINavigationController, nav.viewControllers.first is ORKPasscodeViewController {
            return true
        }
        return false
    }
}
