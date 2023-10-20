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

import AuthenticationServices
import Foundation
import OTFResearchKit
import OTFUtilities
import Combine

public class SignInWithAppleStep: ORKInstructionStep {
    /// The contact information to be requested from the user during authentication.
    public var requestedScopes: [ASAuthorization.Scope]

    public init(identifier: String,
         title: String! = nil,
         text: String! = nil,
         requestedScopes: [ASAuthorization.Scope] = [.email]) {
        
        self.requestedScopes = requestedScopes
        super.init(identifier: identifier)
        self.title = Constants.CustomiseStrings.signinWithApple
        self.text = Constants.CustomiseStrings.signAppleIdFastWay
    }

    @available(*, unavailable)
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class SignInWithAppleStepViewController: ORKInstructionStepViewController,
                                                ASAuthorizationControllerDelegate {
    
    let authType: AuthType
    var disposables: AnyCancellable?
    
    /// The step presented by the step view controller.
    public var signInWithAppleStep: SignInWithAppleStep! {
        return step as? SignInWithAppleStep
    }
    
    init(authType: AuthType, step: ORKStep?) {
        self.authType = authType
        
        super.init(step: step)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
   
        continueButtonTitle  = NSLocalizedString(
            Constants.CustomiseStrings.signinWithApple,
            comment: "Please use Apple's official translations"
        )
        
    }

    public override func goForward() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = signInWithAppleStep?.requestedScopes ?? [.email]

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
                    OTFError("error in reset request -> %{public}@.", error.error.message)
                    alert.dismiss(animated: true) {
                        self.showAlert(title: Constants.CustomiseStrings.okay, message: error.error.message)
                        self.taskViewController?.present(alert, animated: true)
                        self.showError(error)
                    }
                default: break;
                }
            }, receiveValue: { result in
                alert.dismiss(animated: true, completion: nil)
                super.goForward()
            })
    }

    public func authorizationController(controller: ASAuthorizationController,
                                        didCompleteWithError error: Error) {
        showError(error)
    }

    private func showError(_ error: Error) {
        Alerts.showInfo(
            self,
            title: "Error",// NSLocalizedString("Failed to Sign in with Apple", comment: ""),
            message: error.localizedDescription
        )
    }
}

