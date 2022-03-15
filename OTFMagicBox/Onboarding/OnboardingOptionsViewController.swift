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

import OTFResearchKit
import AuthenticationServices
import GoogleSignIn
import OTFCloudClientAPI

public class OnboardingOptionsStep: ORKQuestionStep {
    public override init(
        identifier: String
    ) {
        super.init(identifier: identifier)
        self.answerFormat = ORKAnswerFormat.booleanAnswerFormat()
    }
    
    @available(*, unavailable)
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

public class OnboardingOptionsViewController: ORKQuestionStepViewController, ASAuthorizationControllerDelegate {
    let authType: AuthType
    
    public var CKMultipleSignInStep: OnboardingOptionsStep!{
        return step as? OnboardingOptionsStep
    }
    
    init(authType: AuthType, step: ORKStep?) {
        self.authType = authType
        
        super.init(step: step)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        
        ///Sign in label
        let signInLabel = UILabel(frame: CGRect(x: 0, y: 100, width: 450, height: 50 ))
        signInLabel.center.x = view.center.x
        signInLabel.text = "Sign In"
        signInLabel.textColor = .black
        signInLabel.textAlignment = NSTextAlignment.center
        self.view.addSubview(signInLabel)
        
        let config = YmlReader()
        var button:UIButton? = nil
        
        let buttonUserPassWord = customButton(title: "Sign in with Email and Password", backGroundColor: .white, textColor: .black,
                                              borderColor: .black, reference: button, action: #selector(loginEmailAndPaswwordAction))
        self.view.addSubview(buttonUserPassWord)
        button = buttonUserPassWord
        
        if config.showGoogleLogin == true {
            let buttonGoogle = customButton(title: "Sign in with Google", backGroundColor: .white, textColor: .gray,
                                            borderColor: UIColor(red: 66.0/255.0, green: 133.0/255.0, blue: 244.0/255.0, alpha: 1),
                                            reference: button, action: #selector(loginGoogleAction), withAttachement: "google")
            self.view.addSubview(buttonGoogle)
            button = buttonGoogle
        }
        
        if config.showAppleLogin == true {
            let buttonApple = customButton(title: "Sign in with Apple", backGroundColor: .black, textColor: .white, borderColor: nil,
                                           reference: button, action: #selector(loginAppleAction), withAttachement: "apple")
            self.view.addSubview(buttonApple)
            button = buttonApple
        }
        
        self.view.backgroundColor = .white
    }
    
    public func customButton(
        title: String,
        backGroundColor: UIColor,
        textColor: UIColor,
        borderColor: UIColor?,
        reference: UIButton?,
        action: Selector,
        withAttachement image: String = "",
        imageOffset: CGFloat = 50
    ) -> UIButton {
        let button = UIButton(frame: CGRect(x: 200, y: 200, width: 350, height: 50))
        button.center = view.center
        if let reference = reference {
            button.center.y = reference.center.y - 60
        }
        else {
            button.center.y = CGFloat(Float(view.frame.maxY) - 200)
        }
        button.setTitle(title, for: .normal)
        
        button.setTitleColor(textColor,for: .normal)
        button.addTarget(self,action: action,for: .touchUpInside)
        button.layer.cornerRadius = 10
        button.backgroundColor = backGroundColor
        
        if let borderColor=borderColor {
            button.layer.borderWidth = 2
            button.layer.borderColor =  borderColor.cgColor
        }
        
        if(image != "") {
            button.setImage(UIImage(named: image)!, for: .normal)
            button.imageEdgeInsets.left = -imageOffset
        }
        return button
    }
    
    @objc
    func loginEmailAndPaswwordAction() {
        self.setAnswer(true)
        super.goForward()
    }
    
    private var currentNonce: String!
    
    @objc
    func loginAppleAction() {
        currentNonce = .makeRandomNonce()
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email]
        request.nonce = currentNonce.sha256
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
    public func authorizationController(controller: ASAuthorizationController,
                                        didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("Unable to obtain AppleID credentials")
            return
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            return
        }
        
        // We are using this identity token to get other required fields e.g. email of the user.
        // The JWT token's payload is decided by Apple itself. We should be cautious that Apple
        // may change the format/composition of the token in the future.
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            return
        }
        
        let alert = UIAlertController(title: nil,
                                      message: authType == .login ? "Signing in..." : "Signing up...",
                                      preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        
        taskViewController?.present(alert, animated: true)
        
        OTFTheraforgeNetwork.shared.socialLoginRequest(userType: .patient,
                                                       socialType: .apple,
                                                       authType: authType,
                                                       idToken: idTokenString) { result in
            DispatchQueue.main.async {
                print(result)
                switch result {
                case .failure(let error):
                    print(error.localizedDescription)
                    alert.dismiss(animated: true) {
                        let alert = UIAlertController(title: nil,
                                                      message: error.error.message,
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
                        self.taskViewController?.present(alert, animated: true)
                        self.showError(error)
                    }
                    
                case .success:
                    alert.dismiss(animated: true, completion: nil)
                    self.setAnswer(false)
                    super.goForward()
                }
            }
        }
    }
    
    @objc
    func loginGoogleAction() {
        guard let clientID = YmlReader().googleClientID else {
            showError(ForgeError(error: .init(statusCode: 401, name: "Missing Credentials",
                                              message: "You have not provided Google Client ID in the YAML file.", code: nil)))
            return
        }
        
        let signInConfig = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: self) { [unowned self] user, error in
            if let error = error {
                showError(error)
                return
            }
            
            // If sign in succeeded, display the app's main content View.
            guard let user = user, let idToken = user.authentication.idToken else {
                showError(ForgeError.empty)
                return
            }
            
            signInToTheraForgeWith(idToken: idToken)
        }
    }
    
    func signInToTheraForgeWith(idToken: String) {
        let alert = UIAlertController(title: nil,
                                      message: authType == .login ? "Signing in..." : "Signing up...",
                                      preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        
        taskViewController?.present(alert, animated: true)
        
        OTFTheraforgeNetwork.shared.socialLoginRequest(userType: .patient,
                                                       socialType: .gmail,
                                                       authType: authType,
                                                       idToken: idToken) { result in
            DispatchQueue.main.async {
                print(result)
                switch result {
                case .failure(let error):
                    print(error.localizedDescription)
                    alert.dismiss(animated: true) {
                        let alert = UIAlertController(title: nil,
                                                      message: error.error.message,
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
                        self.taskViewController?.present(alert, animated: true)
                        self.showError(error)
                    }
                    
                case .success:
                    alert.dismiss(animated: true, completion: nil)
                    self.setAnswer(false)
                    super.goForward()
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        // with your request to Google.
        print("Sign in with Google errored: \(error)")
        Alerts.showInfo(
            title: NSLocalizedString("Failed to Sign in with Google", comment: ""),
            message: error.localizedDescription
        )
    }
}

import CryptoKit

fileprivate extension String {
    var sha256: String {
        return SHA256.hash(data: Data(utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
    
    /// Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    static func makeRandomNonce(ofLength length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            for random in randoms {
                if remainingLength == 0 {
                    break
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
}
