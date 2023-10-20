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

import Foundation
import OTFResearchKit
import OTFUtilities
import Combine
/**
 The LoginViewController provides the default login view from ResearchKit.
 */

class LoginViewController: ORKLoginStepViewController {
    
    var subscriptions = Set<AnyCancellable>()
    var disposables: AnyCancellable?
    
    lazy var authButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .blue
        button.layer.cornerRadius = 10.0
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        if LocalAuthentication.shared.hasFaceId() {
            button.setTitle(Constants.CustomiseStrings.faceId, for: .normal)
        } else {
            button.setTitle(Constants.CustomiseStrings.touchId, for: .normal)
        }
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        authButton.addTarget(self, action: #selector(customButtonTapped), for: .touchUpInside)
        view.addSubview(authButton)
        addAuthButtonConstraints()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name: UIResponder.keyboardWillShowNotification, object: nil);
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(sender:)), name: UIResponder.keyboardWillHideNotification, object: nil);
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
        if view.subviews.count == 0 {
            return subviewArray
        }
        for subview in view.subviews {
            subviewArray += self.getSubviewsOfView(view: subview) as [T]
            if let subview = subview as? T {
                subviewArray.append(subview)
            }
        }
        return subviewArray
    }
    
    @objc func customButtonTapped() {
        LocalAuthentication.shared.authenticationWithTouchID { success in
            if success {
                let emailFromKeychain = KeychainCloudManager.getEmailAddress
                let passwordFromKeychain = KeychainCloudManager.getPassword
                if !emailFromKeychain.isEmpty {
                    DispatchQueue.main.async {
                        let textFields: [UITextField] = self.getSubviewsOfView(view: self.view)
                        for item in textFields {
                            if item.isSecureTextEntry {
                                item.text = passwordFromKeychain
                            } else {
                                item.text = emailFromKeychain
                            }
                        }
                        
                        let button: [UIButton] = self.getSubviewsOfView(view: self.view)
                        for item in button {
                            if item.currentTitle == "Login" {
                                item.isEnabled = true
                                item.isUserInteractionEnabled = true
                            }
                        }
                    }
                } else {
                    if LocalAuthentication.shared.hasFaceId() {
                        self.showAlert(title: "Alert", message: Constants.CustomiseStrings.faceIdAlertMessage)
                    } else {
                        self.showAlert(title: "Alert", message: Constants.CustomiseStrings.touchIdAlertMessage)
                    }
                }
            } else {
                print("error")
            }
        }
    }
    
    override func goForward() {
        
        var emailAddress = String()
        var password = String()
        let textFields: [UITextField] = self.getSubviewsOfView(view: self.view)
        for item in textFields {
            if item.isSecureTextEntry {
                password = item.text ?? ""
            } else {
                emailAddress = item.text ?? ""
            }
        }
        
        loginRequest(email: emailAddress, password: password)
    }
    
    func loginRequest(email: String, password: String) {
        
        let alert = UIAlertController(title: nil, message: Constants.CustomiseStrings.loginingIn, preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        
        taskViewController?.present(alert, animated: true, completion: nil)
        disposables = OTFTheraforgeNetwork.shared.loginRequest(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { response in
                switch response {
                case .failure(let error):
                    OTFError("error in login request -> %{public}@.", error.error.message)
                    alert.dismiss(animated: true) {
                        self.showAlert(title: Constants.CustomiseStrings.loginInError, message: error.error.message )
                    }
                default: break;
                }
            } receiveValue: { result in
                self.saveValuesToLocal(email: email, password: password, encryptedDefaultStorageKeyHex: result.data.encryptedDefaultStorageKey, encryptedconfidentialStorageKeyHex: result.data.encryptedConfidentialStorageKey)
                self.synchronizedDatabase { _ in
                alert.dismiss(animated: false, completion: {
                        super.goForward()
                })
                }
                
            }
    }
    
    func synchronizedDatabase(completion: ((Error?) -> Void)?){
        DispatchQueue.main.async {
            CloudantSyncManager.shared.syncCloudantStore(notifyWhenDone: true) {
                result in
                completion?(result)
            }
        }
        
        
    }
    
    func saveValuesToLocal(email: String, password: String, encryptedDefaultStorageKeyHex: String, encryptedconfidentialStorageKeyHex: String){
        let swiftSodium = SwiftSodium()
        let masterKey = swiftSodium.generateMasterKey(password: password, email: email)
        let keyPair = swiftSodium.sodium.box.keyPair(seed: masterKey)
        
        
        
        if let keyPair = keyPair {
            let encryptedDefaultStorageKey = swiftSodium.getArrayOfBytesFromData(FileData: swiftSodium.hexStringToData(string: encryptedDefaultStorageKeyHex) as NSData)
            let defaultStorageKey = swiftSodium.decryptKey(bytes: encryptedDefaultStorageKey, publicKey: keyPair.publicKey, secretKey: keyPair.secretKey)
            
            let encryptedconfidentialStorageKey = swiftSodium.getArrayOfBytesFromData(FileData: swiftSodium.hexStringToData(string: encryptedconfidentialStorageKeyHex) as NSData)
            let confidentialStorageKey = swiftSodium.decryptKey(bytes: encryptedconfidentialStorageKey, publicKey: keyPair.publicKey, secretKey: keyPair.secretKey)
            
            KeychainCloudManager.saveValuesInKeychain(email: email, password: password, masterKey: masterKey, publicKey: keyPair.publicKey, secretKey: keyPair.secretKey, defaultStorageKey: defaultStorageKey, confidentialStorageKey: confidentialStorageKey)
        }
    }
    // Forgot password.
    override func forgotPasswordButtonTapped() {
        let alert = UIAlertController(title: Constants.CustomiseStrings.resetPassword, message: Constants.CustomiseStrings.enterYourEmailToGetLink, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = Constants.CustomiseStrings.enterYourEmail
        }
        
        alert.addAction(UIAlertAction(title: Constants.CustomiseStrings.submit, style: .default) { (_) in
            guard let email = alert.textFields![0].text else{ return }
            if email.isValidEmail {
                
                self.disposables = OTFTheraforgeNetwork.shared.forgotPassword(email: email)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { response in
                        switch response {
                        case .failure(let error):
                            OTFError("error in forgot request -> %{public}@.", error.error.message)
                            DispatchQueue.main.async {
                                self.showAlert(title: Constants.CustomiseStrings.forgotPassword, message: error.error.message)
                            }
                        default: break;
                        }
                    }, receiveValue: { result in
                        DispatchQueue.main.async {
                            self.resetPassword(email: email)
                        }
                    })
                
            }else {
                self.showAlert(title: Constants.CustomiseStrings.resetPassword, message: Constants.CustomiseStrings.enterValidEmail)
            }
        })
        
        alert.addAction(UIAlertAction(title: Constants.CustomiseStrings.cancel, style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    // Reset password for the givem email.
    func resetPassword(email: String) {
        let alert = UIAlertController(title: Constants.CustomiseStrings.resetPassword, message: Constants.CustomiseStrings.enterTheCode, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Code "
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = Constants.CustomiseStrings.newPassword
            textField.isSecureTextEntry = true
            
        }
        alert.addAction(UIAlertAction(title: Constants.CustomiseStrings.submit, style: .default) { _ in
            guard let code = alert.textFields![0].text else {
                fatalError("Invalid code")
            }
            guard let newPassword = alert.textFields![1].text else {
                fatalError("Invalid password")
            }
            
            self.disposables = OTFTheraforgeNetwork.shared.resetPassword(email: email, code: code, newPassword: newPassword)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { response in
                    switch response {
                    case .failure(let error):
                        OTFError("error in reset request -> %{public}@.", error.error.message)
                        DispatchQueue.main.async {
                            self.showAlert(title: Constants.CustomiseStrings.passwordResetError, message: error.error.message)
                        }
                    default: break;
                    }
                }, receiveValue: { result in
                    DispatchQueue.main.async {
                        self.showAlert(title: Constants.CustomiseStrings.passwordUpdated, message: "")
                    }
                })
        })
        alert.addAction(UIAlertAction(title: Constants.CustomiseStrings.cancel, style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    func addAuthButtonConstraints() {
        
        NSLayoutConstraint.activate([
            authButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            authButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150),
            authButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            authButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            authButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
 
