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

import OTFResearchKit
import OTFUtilities
import Combine
import OTFCloudClientAPI

enum LoginFailureRoute: Equatable {
    case resendVerificationEmail
    case showLoginError(message: String)
}

enum LoginSuccessRoute: Equatable {
    case patient(encryptedDefaultStorageKeyHex: String?, encryptedConfidentialStorageKeyHex: String?)
    case doctorPortal(URL)
}

struct LoginRouteResolver {
    static let verificationStatusCode = 601

    let doctorPortalURLString: String

    func failureRoute(for error: ForgeError) -> LoginFailureRoute {
        guard error.error.statusCode == Self.verificationStatusCode else {
            return .showLoginError(message: error.error.message)
        }

        return .resendVerificationEmail
    }

    func successRoute(for response: Response.Login) -> LoginSuccessRoute? {
        guard response.data.type != .patient else {
            return .patient(
                encryptedDefaultStorageKeyHex: response.data.encryptedDefaultStorageKey,
                encryptedConfidentialStorageKeyHex: response.data.encryptedConfidentialStorageKey
            )
        }

        guard let url = URL(string: doctorPortalURLString) else { return nil }
        return .doctorPortal(url)
    }
}

struct LoginCredentials: Equatable {
    let email: String
    let password: String
}

enum LoginCredentialExtractor {
    static func credentials(from stepResult: ORKStepResult?) -> LoginCredentials? {
        guard let textResults = stepResult?.results?.compactMap({ $0 as? ORKTextQuestionResult }),
              textResults.count >= 2,
              let email = textResults.first?.textAnswer,
              let password = textResults.last?.textAnswer
        else {
            return nil
        }

        return LoginCredentials(email: email, password: password)
    }
}

class LoginViewController: ORKLoginStepViewController {

    private let logger = OTFLogger.logger()
    private lazy var styleConfig = StyleConfigurationLoader.config
    private lazy var auth = AuthConfigurationLoader.auth
    
    var subscriptions = Set<AnyCancellable>()
    var disposables: AnyCancellable?
    
    lazy var authButton: UIButton = {
        let button = UIButton()
        let tint = styleConfig.activeStyle.tintColor.uiColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 10.0
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = tint
        if LocalAuthentication.shared.hasFaceId() {
            button.setTitle(auth.faceIdButtonTitle.localized, for: .normal)
        } else {
            button.setTitle(auth.touchIdButtonTitle.localized, for: .normal)
        }
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authButton.addTarget(self, action: #selector(customButtonTapped), for: .touchUpInside)
        addAuthButtonConstraints()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(sender:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(sender: NSNotification) {
        authButton.removeFromSuperview()
    }
    
    @objc func keyboardWillHide(sender: NSNotification) {
        view.addSubview(authButton)
        addAuthButtonConstraints()
    }

    func getSubviewsOfView<T: UIView>(view: UIView) -> [T] {
        var subviewArray = [T]()
        if view.subviews.isEmpty {
            return subviewArray
        }
        for subview in view.subviews {
            subviewArray += self.getSubviewsOfView(view: subview) as [T]
            if let subview = subview as? T {
                logger.info("Subview collected: \(subview)")
                subviewArray.append(subview)
            }
        }
        return subviewArray
    }
    
    @objc func customButtonTapped() {
        LocalAuthentication.shared.authenticationWithTouchID { [weak self] success in
            guard let self = self else { return }
            if success {
                let email = KeychainCloudManager.getEmailAddress
                let password = KeychainCloudManager.getPassword
                if !email.isEmpty {
                    DispatchQueue.main.async {
                        self.loginRequest(email: email, password: password)
                    }
                } else {
                    let title = self.auth.genericErrorTitle.localized
                    let message = LocalAuthentication.shared.hasFaceId() ? self.auth.faceIdAlertMessage.localized : self.auth.touchIdAlertMessage.localized
                    self.showAlert(title: title, message: message)
                }
            } else {
                self.logger.error("LocalAuthentication failed.")
            }
        }
    }

    override func goForward() {
        guard let credentials = LoginCredentialExtractor.credentials(from: result) else {
            logger.error("Missing email or password in Login step result.")
            return
        }
        loginRequest(email: credentials.email, password: credentials.password)
    }
    
    func loginRequest(email: String, password: String) {
        let hud = presentBlockingHUD(message: auth.signingInMessage.localized)

        disposables = OTFTheraforgeNetwork.shared.loginRequest(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                if case let .failure(error) = completion {
                    hud.dismiss(animated: true) {
                        switch LoginRouteResolver(doctorPortalURLString: self.auth.doctorPortalUrl).failureRoute(for: error) {
                        case .resendVerificationEmail:
                            self.showResendEmailVerifyAlert(
                                title: self.auth.emailVerifyConfirmationTitle.localized,
                                message: self.auth.emailVerifyMessage.localized
                            ) { _ in
                                self.disposables = OTFTheraforgeNetwork.shared.resendVerificationEmail(email: email)
                                    .receive(on: DispatchQueue.main)
                                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                            }
                        case .showLoginError(let message):
                            self.showAlert(title: self.auth.loginErrorTitle.localized, message: message)
                        }
                    }
                }
            } receiveValue: { [weak self] result in
                guard let self = self else { return }

                switch LoginRouteResolver(doctorPortalURLString: self.auth.doctorPortalUrl).successRoute(for: result) {
                case .patient(let encryptedDefaultStorageKeyHex, let encryptedConfidentialStorageKeyHex):
                    CareKitStoreManager.shared.setWatchSyncReady(false)
                    self.saveUserCrredentials(email: email, password: password)
                    if let defHex = encryptedDefaultStorageKeyHex,
                       let confHex = encryptedConfidentialStorageKeyHex {
                        self.saveUserKeysToLocal(email: email, password: password,
                                                 encryptedDefaultStorageKeyHex: defHex,
                                                 encryptedconfidentialStorageKeyHex: confHex)
                    }
                    _ = WatchAuthSessionStore.shared.beginPendingLoginSession()
                    self.synchronizeDatabaseInBackground()
                    hud.dismiss(animated: false) {
                        self.advanceAfterSuccessfulLogin()
                    }
                case .doctorPortal(let url):
                    hud.dismiss(animated: true) { [weak self] in
                        guard let self = self else { return }
                        self.confirmDoctorPortalOpen(url: url, email: email)
                    }
                case nil:
                    hud.dismiss(animated: true)
                }
            }
    }

    func synchronizedDatabase(completion: ((Error?) -> Void)?) {
        DispatchQueue.main.async {
            CloudantSyncManager.shared.syncCloudantStore(notifyWhenDone: true) { result in
                completion?(result)
            }
        }
    }

    /// Runs the first post-login Cloudant sync before the watch login is committed.
    ///
    /// The pending watch auth command has already been stored by `WatchAuthSessionStore`.
    /// `CloudantSyncManager` publishes and commits it only after this sync succeeds and
    /// the command has been written to WatchConnectivity's application context.
    private func synchronizeDatabaseInBackground() {
        synchronizedDatabase { [weak self] result in
            if let result {
                self?.logger.error("LoginViewController: Background database sync failed: \(result.localizedDescription)")
                return
            }
        }
    }
    
    func saveUserCrredentials(email: String, password: String) {
        KeychainCloudManager.saveUserCredentialsInKeychain(email: email, password: password)
    }
    
    func saveUserKeysToLocal(email: String, password: String, encryptedDefaultStorageKeyHex: String, encryptedconfidentialStorageKeyHex: String) {
        let swiftSodium = SwiftSodium()

        do {
            let masterKey = try swiftSodium.generateMasterKey(password: password, email: email)
            guard let keyPair = swiftSodium.sodium.box.keyPair(seed: masterKey) else {
                logger.error("Failed to generate key pair from master key.")
                return
            }

            let encryptedDefaultBytes = Array(try swiftSodium.hexStringToData(encryptedDefaultStorageKeyHex))
            let encryptedConfidentialBytes = Array(try swiftSodium.hexStringToData(encryptedconfidentialStorageKeyHex))

            let defaultStorageKey = try swiftSodium.decryptSealedBox(
                bytes: encryptedDefaultBytes,
                recipientPublicKey: keyPair.publicKey,
                recipientSecretKey: keyPair.secretKey
            )
            let confidentialStorageKey = try swiftSodium.decryptSealedBox(
                bytes: encryptedConfidentialBytes,
                recipientPublicKey: keyPair.publicKey,
                recipientSecretKey: keyPair.secretKey
            )

            KeychainCloudManager.saveUserKeys(
                masterKey: masterKey,
                publicKey: keyPair.publicKey,
                secretKey: keyPair.secretKey,
                defaultStorageKey: defaultStorageKey,
                confidentialStorageKey: confidentialStorageKey
            )
        } catch {
            logger.error("saveUserKeysToLocal failed: \(error.localizedDescription)")
        }
    }

    // Forgot password.
    override func forgotPasswordButtonTapped() {
        let alert = UIAlertController(
            title: auth.resetPasswordTitle.localized,
            message: auth.enterYourEmailToGetLink.localized,
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = self.auth.enterYourEmailPlaceholder.localized
        }
        
        alert.addAction(UIAlertAction(title: auth.submitActionTitle.localized, style: .default) { [self] _ in
            guard let email = alert.textFields?.first?.text else {
                logger.error("Missing email in forgot password prompt.")
                return
            }
            if email.isValidEmail {
                self.disposables = OTFTheraforgeNetwork.shared.forgotPassword(email: email)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { [self] response in
                        switch response {
                        case .failure(let error):
                            logger.error("Error in forgot password request -> \(error.error.message)")
                            DispatchQueue.main.async {
                                self.showAlert(title: self.auth.forgotPasswordTitle.localized, message: error.error.message)
                            }
                        default: break
                        }
                    }, receiveValue: { _ in
                        DispatchQueue.main.async {
                            self.resetPassword(email: email)
                        }
                    })
            } else {
                self.showAlert(title: self.auth.resetPasswordTitle.localized, message: self.auth.enterValidEmailMessage.localized)
            }
        })
        
        alert.addAction(UIAlertAction(title: auth.cancelActionTitle.localized, style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    // Reset password for the given email.
    func resetPassword(email: String) {
        let alert = UIAlertController(
            title: auth.resetPasswordTitle.localized,
            message: auth.enterTheCodeMessage.localized,
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Code"
        }
        
        alert.addTextField { textField in
            textField.placeholder = self.auth.newPasswordPlaceholder.localized
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: auth.submitActionTitle.localized, style: .default) { [self] _ in
            let code = alert.textFields?.first?.text ?? ""
            let newPassword = alert.textFields?.dropFirst().first?.text ?? ""
            
            guard !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                logger.error("Reset password: empty code provided.")
                self.showAlert(title: self.auth.passwordResetErrorTitle.localized, message: self.auth.enterTheCodeMessage.localized)
                return
            }
            guard !newPassword.isEmpty else {
                logger.error("Reset password: empty new password provided.")
                self.showAlert(title: self.auth.passwordResetErrorTitle.localized, message: self.auth.passwordInvalidMessage.localized)
                return
            }
            
            self.disposables = OTFTheraforgeNetwork.shared.resetPassword(email: email, code: code, newPassword: newPassword)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [self] response in
                    switch response {
                    case .failure(let error):
                        logger.error("Error in reset password request -> \(error.error.message)")
                        DispatchQueue.main.async {
                            self.showAlert(title: self.auth.passwordResetErrorTitle.localized, message: error.error.message)
                        }
                    default: break
                    }
                }, receiveValue: { _ in
                    DispatchQueue.main.async {
                        self.showAlert(title: self.auth.passwordUpdatedTitle.localized, message: "")
                    }
                })
        })
        
        alert.addAction(UIAlertAction(title: auth.cancelActionTitle.localized, style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    func findLoginButton(in view: UIView) -> UIButton? {
        for subview in view.subviews {
            if let button = subview as? UIButton, button.currentTitle == auth.loginTitle.localized {
                return button
            }
            if let found = findLoginButton(in: subview) {
                return found
            }
        }
        return nil
    }
    
    func addAuthButtonConstraints() {
        guard let loginBtn = findLoginButton(in: view) else { return }
        guard let loginSuperView = loginBtn.superview else { return }
        guard let sSuperView = loginSuperView.superview else { return }
        
        sSuperView.addSubview(authButton)
        NSLayoutConstraint.activate([
            authButton.centerXAnchor.constraint(equalTo: sSuperView.centerXAnchor),
            authButton.bottomAnchor.constraint(equalTo: loginSuperView.topAnchor, constant: 0),
            authButton.leadingAnchor.constraint(equalTo: sSuperView.leadingAnchor, constant: 20),
            authButton.trailingAnchor.constraint(equalTo: sSuperView.trailingAnchor, constant: -20),
            authButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func advanceAfterSuccessfulLogin() {
        super.goForward()
    }

    @MainActor
    private func confirmDoctorPortalOpen(url: URL, email: String) {
        let host = url.host ?? url.absoluteString
        let message = String(format: auth.doctorPortalConfirmMessage.localized, host)
        let alert = UIAlertController(title: auth.doctorPortalConfirmTitle.localized, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: auth.cancelActionTitle.localized, style: .cancel))
        alert.addAction(UIAlertAction(title: auth.openActionTitle.localized, style: .default) { _ in
            UIApplication.shared.open(url)
        })
        present(alert, animated: true)
    }
}
