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
import AuthenticationServices
import GoogleSignIn
import OTFCloudClientAPI
import OTFUtilities
import Combine
import UIKit

final class SignInOptionsStep: ORKQuestionStep {
    override init(identifier: String) {
        super.init(identifier: identifier)
        answerFormat = ORKAnswerFormat.booleanAnswerFormat()
    }
    
    @available(*, unavailable)
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SignInOptionsViewController: ORKStepViewController, ASAuthorizationControllerDelegate {
    
    enum ButtonStyleType {
        case filled
        case bordered
    }
    
    // MARK: - Properties
    
    private let auth = AuthConfigurationLoader.auth
    private let authType: AuthType
    private var disposables: AnyCancellable?
    private var currentNonce: String!
    private let logger = OTFLogger.logger()
    private lazy var styleConfig = StyleConfigurationLoader.config

    private var producedResult: ORKStepResult?
    
    override var result: ORKStepResult? {
        producedResult ?? super.result
    }
    
    // MARK: - Init
    
    init(authType: AuthType, step: ORKStep?) {
        self.authType = authType
        super.init(step: step)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        skipButtonItem = nil
        setupViews()
    }
    
    // MARK: - Result + Navigation

    private func setPredicateAnswer(isEmailFlow: Bool) {
        let id = step?.identifier ?? Constants.Auth.signInButtons
        let boolean = ORKBooleanQuestionResult(identifier: id)
        boolean.booleanAnswer = NSNumber(value: isEmailFlow)
        producedResult = ORKStepResult(stepIdentifier: id, results: [boolean])
    }
    
    private func advance() {
        super.goForward()
    }
    
    // MARK: - UI
    
    private func makeButton(
        title: String,
        style: ButtonStyleType,
        backgroundColor: UIColor? = nil,
        foregroundColor: UIColor,
        strokeColor: UIColor? = nil,
        imageName: String? = nil,
        tintImage: Bool = false,
        fontSize: CGFloat = 17,
        fontWeight: UIFont.Weight = .regular
    ) -> UIButton {
        
        var config: UIButton.Configuration
        switch style {
        case .filled:
            config = UIButton.Configuration.filled()
            config.cornerStyle = .medium
            if let bgColor = backgroundColor {
                config.baseBackgroundColor = bgColor
            }
        case .bordered:
            config = UIButton.Configuration.plain()
            var bg = UIBackgroundConfiguration.clear()
            bg.backgroundColor = .systemBackground
            bg.cornerRadius = 10
            if let stroke = strokeColor {
                bg.strokeColor = stroke
                bg.strokeWidth = 2
            }
            config.background = bg
        }
        
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        config.title = title
        config.baseForegroundColor = foregroundColor
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
            return outgoing
        }
        
        if let name = imageName, let uiImage = UIImage(named: name) {
            let resized = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { _ in
                uiImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 24, height: 24)))
            }

            if tintImage {
                config.image = resized.withRenderingMode(.alwaysTemplate)
                config.imageColorTransformer = UIConfigurationColorTransformer { _ in
                    foregroundColor
                }
            } else {
                config.image = resized.withRenderingMode(.alwaysOriginal)
                config.imageColorTransformer = nil
            }

            config.imagePlacement = .leading
            config.imagePadding = 8
        }
        
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        
        return button
    }

    private func setupViews() {
        let style = styleConfig.activeStyle

        // Container
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .clear
        view.addSubview(container)
        
        // Stack
        let verticalStack = UIStackView()
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        verticalStack.axis = .vertical
        verticalStack.spacing = 12
        verticalStack.alignment = .fill
        verticalStack.distribution = .fill
        container.addSubview(verticalStack)
        
        // Icon (optional)
        let iconView = UIImageView(image: UIImage(systemName: auth.loginOptionsIcon))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = style.tintColor.uiColor
        iconView.contentMode = .scaleAspectFit
        container.addSubview(iconView)
        
        // Description
        let signInLabel = UILabel()
        signInLabel.translatesAutoresizingMaskIntoConstraints = false
        signInLabel.text = auth.loginOptionsText.localized
        signInLabel.textColor = .label
        signInLabel.font = .systemFont(ofSize: 18, weight: .regular)
        signInLabel.textAlignment = .center
        signInLabel.numberOfLines = 0
        container.addSubview(signInLabel)
        
        // Buttons
        if auth.showAppleLogin {
            let apple = makeButton(
                title: authType == .signup ? auth.signUpWithApple.localized : auth.signInWithApple.localized,
                style: .filled,
                backgroundColor: .label,
                foregroundColor: .systemBackground,
                imageName: "apple-login",
                tintImage: true
            )
            apple.heightAnchor.constraint(equalToConstant: 50).isActive = true
            apple.addTarget(self, action: #selector(loginAppleAction), for: .touchUpInside)
            verticalStack.addArrangedSubview(apple)
        }

        if auth.showGoogleLogin {
            let googleBlue = UIColor(red: 66/255, green: 133/255, blue: 244/255, alpha: 1)
            let google = makeButton(
                title: authType == .signup ? auth.signUpWithGoogle.localized : auth.signInWithGoogle.localized,
                style: .bordered,
                foregroundColor: .label,
                strokeColor: googleBlue,
                imageName: "google"
            )
            google.heightAnchor.constraint(equalToConstant: 50).isActive = true
            google.addTarget(self, action: #selector(loginGoogleAction), for: .touchUpInside)
            verticalStack.addArrangedSubview(google)
        }

        let email = makeButton(
            title: authType == .signup ? auth.signUpWithEmail.localized : auth.signInWithEmail.localized,
            style: .bordered,
            foregroundColor: .label,
            strokeColor: style.borderColor.uiColor
        )
        email.heightAnchor.constraint(equalToConstant: 50).isActive = true
        email.addTarget(self, action: #selector(loginEmailAndPasswordAction), for: .touchUpInside)
        verticalStack.addArrangedSubview(email)
        
        // Layout
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -48),
            
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: container.topAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 120),
            iconView.widthAnchor.constraint(equalToConstant: 120),
            
            signInLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            signInLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            signInLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            verticalStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            verticalStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            verticalStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func loginEmailAndPasswordAction() {
        setPredicateAnswer(isEmailFlow: true)
        advance()
    }
    
    @objc private func loginAppleAction() {
        currentNonce = .makeRandomNonce()
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email]
        request.nonce = currentNonce.sha256
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = cred.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8)
        else {
            logger.error("Unable to obtain Apple identity token")
            return
        }

        let hud = presentBlockingHUD(message: authType == .login ? auth.signingInMessage.localized : auth.signingUpMessage.localized)
        disposables = OTFTheraforgeNetwork.shared
            .socialLoginRequest(userType: .patient, socialType: .apple, authType: authType, idToken: idToken)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                hud.dismiss(animated: true)
                if case let .failure(error) = completion {
                    self.showAlert(title: self.auth.loginErrorTitle.localized, message: error.error.message)
                }
            }, receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.setPredicateAnswer(isEmailFlow: false)
                self.advance()
            })
    }

    @objc private func loginGoogleAction() {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] user, error in
            guard let self = self else { return }

            if let error {
                self.showError(error)
                return
            }
            guard let idToken = user?.user.idToken?.tokenString else {
                self.showError(ForgeError.empty)
                return
            }

            let hud = self.presentBlockingHUD(message: self.authType == .login
                                              ? self.auth.signingInMessage.localized
                                              : self.auth.signingUpMessage.localized)

            self.disposables = OTFTheraforgeNetwork.shared
                .socialLoginRequest(userType: .patient, socialType: .gmail, authType: self.authType, idToken: idToken)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    hud.dismiss(animated: true)
                    if case let .failure(error) = completion {
                        self.showAlert(title: self.auth.googleSignInFailedTitle.localized, message: error.error.message)
                    }
                }, receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    self.setPredicateAnswer(isEmailFlow: false)
                    self.advance()
                })
        }
    }
    
    private func showError(_ error: Error) {
        self.showAlert(title: auth.googleSignInFailedTitle.localized, message: error.localizedDescription)
    }
}
