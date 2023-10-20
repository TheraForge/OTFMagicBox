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
import OTFUtilities
import Combine

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
    var disposables: AnyCancellable?
    
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
        
        setupViews()
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
        button.setTitle(title, for: .normal)
        
        button.setTitleColor(textColor,for: .normal)
        button.addTarget(self,action: action,for: .touchUpInside)
        button.layer.cornerRadius = 10
        button.backgroundColor = backGroundColor
        
        if let borderColor=borderColor {
            button.layer.borderWidth = 2
            button.layer.borderColor =  borderColor.cgColor
        }
        
        if (image != "") {
            button.setImage(UIImage(named: image), for: .normal)
            button.imageEdgeInsets.left = -imageOffset
        }
        
        return button
    }
    
    private func setupViews() {
        
        let verticalStack = UIStackView()
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        verticalStack.spacing = 10
        verticalStack.axis = .vertical
        verticalStack.distribution = .fillEqually
        verticalStack.backgroundColor = .clear
        view.addSubview(verticalStack)
        
        var stackViewHeight = CGFloat(0)
        
        let config = ModuleAppYmlReader()
        
        if YmlReader().showAppleLogin {
            stackViewHeight += 60
            let buttonApple = customButton(title: Constants.CustomiseStrings.signinWithApple, backGroundColor: .black, textColor: .white, borderColor: nil,
                                           reference: nil, action: #selector(loginAppleAction), withAttachement: "apple-login")
            buttonApple.translatesAutoresizingMaskIntoConstraints = false
            verticalStack.addArrangedSubview(buttonApple)
        }
        
        if YmlReader().showGoogleLogin {
            stackViewHeight += 60
            let buttonGoogle = customButton(title: Constants.CustomiseStrings.signinWithGoogle, backGroundColor: .white, textColor: .black,
                                            borderColor: UIColor(red: 66.0/255.0, green: 133.0/255.0, blue: 244.0/255.0, alpha: 1),
                                            reference: nil, action: #selector(loginGoogleAction), withAttachement: "google")
            buttonGoogle.translatesAutoresizingMaskIntoConstraints = false
            verticalStack.addArrangedSubview(buttonGoogle)
        }
        
        stackViewHeight += 50
        let buttonUserPassWord = customButton(title: Constants.CustomiseStrings.signinWithEmail, backGroundColor: .white, textColor: .black,
                                              borderColor: .black, reference: nil, action: #selector(loginEmailAndPaswwordAction))
        buttonUserPassWord.translatesAutoresizingMaskIntoConstraints = false
        verticalStack.addArrangedSubview(buttonUserPassWord)
        
        ///Sign in label
        let signInLabel = UILabel(frame: CGRect(x: 0, y: 320, width: 450, height: 50 ))
        signInLabel.translatesAutoresizingMaskIntoConstraints = false
        signInLabel.center.x = view.center.x
        signInLabel.text =  config.loginOptionsText
        signInLabel.textColor = .black
        signInLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        signInLabel.minimumScaleFactor = 0.75
        signInLabel.textAlignment = NSTextAlignment.center
        signInLabel.numberOfLines = 4
        self.view.addSubview(signInLabel)
        
        var optionsIcon: UIImage?

        if let image = UIImage(systemName: config.loginOptionsIcon) {
            optionsIcon = image
        }
        else {
            optionsIcon = UIImage(systemName: Constants.YamlDefaults.LoginOptionsIcon)
        }

        let iconImage = UIImageView(image: optionsIcon)
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        iconImage.tintColor = .black
        iconImage.frame = CGRect(x: 0, y: 100, width: 200, height: 200)
        iconImage.contentMode = .scaleAspectFit
        iconImage.center.x = view.center.x
        view.addSubview(iconImage)
        
        NSLayoutConstraint.activate([
            iconImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            iconImage.heightAnchor.constraint(equalToConstant: 120),
            iconImage.widthAnchor.constraint(equalToConstant: 120),
            
            signInLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInLabel.topAnchor.constraint(equalTo: iconImage.bottomAnchor),
            signInLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            signInLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            verticalStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            verticalStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            verticalStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            verticalStack.heightAnchor.constraint(equalToConstant: stackViewHeight)
        ])
        
        self.view.backgroundColor = .white
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
            OTFLog("Unable to obtain AppleID credentials")
            return
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
            OTFLog("Unable to fetch identity token")
            return
        }
        
        // We are using this identity token to get other required fields e.g. email of the user.
        // The JWT token's payload is decided by Apple itself. We should be cautious that Apple
        // may change the format/composition of the token in the future.
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            OTFLog("Unable to serialize token string from data:", appleIDToken.debugDescription)
            return
        }
        
        let alert = UIAlertController(title: nil,
                                      message: authType == .login ? Constants.CustomiseStrings.signingIn : Constants.CustomiseStrings.signingUp,
                                      preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        
        taskViewController?.present(alert, animated: true)
        
        
        disposables = OTFTheraforgeNetwork.shared.socialLoginRequest(userType: .patient, socialType: .apple, authType: authType, idToken: idTokenString)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { response in
                switch response {
                case .failure(let error):
                    OTFError("error in social login %{public}@", error.localizedDescription)
                    alert.dismiss(animated: true) {
                        self.showAlert(title: "Ok", message: error.error.message)
                        self.showError(error)
                    }
                default: break;
                }
            }, receiveValue: { result in
                alert.dismiss(animated: true, completion: nil)
                self.setAnswer(false)
                super.goForward()
            })
    }
    
    @objc
    func loginGoogleAction() {
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { user, error in
            
            if let error = error {
                self.showError(error)
                return
            }
            
            // If sign in succeeded, display the app's main content View.
            
            guard let user = user?.user, let idToken = user.idToken?.tokenString else {
                self.showError(ForgeError.empty)
                return
            }
            
            self.signInToTheraForgeWith(idToken: idToken)
        }
    }
    
    func signInToTheraForgeWith(idToken: String) {
        let alert = UIAlertController(title: nil,
                                      message: authType == .login ?  Constants.CustomiseStrings.signingIn : Constants.CustomiseStrings.signingUp,
                                      preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        
        taskViewController?.present(alert, animated: true)
        
        
        
        disposables = OTFTheraforgeNetwork.shared.socialLoginRequest(userType: .patient, socialType: .gmail, authType: authType, idToken: idToken)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { response in
                switch response {
                case .failure(let error):
                    OTFError("error in social login %{public}@", error.localizedDescription)
                    alert.dismiss(animated: true) {
                        self.showAlert(title: Constants.CustomiseStrings.okay, message: error.error.message)
                        self.showError(error)
                    }
                default: break;
                }
            }, receiveValue: { result in
                alert.dismiss(animated: true, completion: nil)
                self.setAnswer(false)
                super.goForward()
            })
    }
    
    private func showError(_ error: Error) {
        // with your request to Google.
        Alerts.showInfo(
            title: NSLocalizedString("Failed to Sign in with Google ", comment: ""),
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
