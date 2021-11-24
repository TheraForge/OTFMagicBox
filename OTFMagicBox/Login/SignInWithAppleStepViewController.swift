//
//  SignInWithAppleStepViewController.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 04.11.21.
//

import AuthenticationServices
import Foundation
import OTFResearchKit

public class SignInWithAppleStep: ORKInstructionStep {
    /// The contact information to be requested from the user during authentication.
    public var requestedScopes: [ASAuthorization.Scope]

    public init(identifier: String,
         title: String! = nil,
         text: String! = nil,
         requestedScopes: [ASAuthorization.Scope] = [.email]) {
        
        self.requestedScopes = requestedScopes
        super.init(identifier: identifier)
        self.title = "Sign in with Apple"
        self.text = "Sign in using your Apple ID is fast and easy, and Apple will not track any of your activities."
    }

    @available(*, unavailable)
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class SignInWithAppleStepViewController: ORKInstructionStepViewController,
                                                ASAuthorizationControllerDelegate {
    
    let authType: AuthType
    
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
            "Sign in with Apple",
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
                                      message: authType == .login ? "Signing in..." : "Siging up...",
                                      preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        
        taskViewController?.present(alert, animated: true, completion: nil)

        OTFTheraforgeNetwork.shared.socialLoginRequest(userType: .patient,
                                                       socialType: .apple,
                                                       authType: authType,
                                                       idToken: idTokenString) { result in
            DispatchQueue.main.async {
                print(result)
                switch result {
                case .failure(let error):
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        alert.dismiss(animated: true) {
                            let alert = UIAlertController(title: nil,
                                                          message: error.localizedDescription,
                                                          preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
                            self.taskViewController?.present(alert, animated: true)
                            self.showError(error)
                        }
                    }
                    
                case .success:
                    DispatchQueue.main.async {
                        alert.dismiss(animated: true, completion: nil)
                        super.goForward()
                    }
                }
            }
        }
    }

    public func authorizationController(controller: ASAuthorizationController,
                                        didCompleteWithError error: Error) {
        showError(error)
    }

    private func showError(_ error: Error) {
        print("Sign in with Apple errored: \(error)")
        Alerts.showInfo(
            self,
            title: "Error",// NSLocalizedString("Failed to Sign in with Apple", comment: ""),
            message: error.localizedDescription
        )
    }
}
