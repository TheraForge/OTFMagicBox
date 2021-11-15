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
    /// The step presented by the step view controller.
    public var signInWithAppleStep: SignInWithAppleStep! {
        return step as? SignInWithAppleStep
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
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            return
        }

        guard let email = appleIDCredential.email else {
            print("Unable to fetch email")
            return
        }

         OTFTheraforgeNetwork.shared.socialLoginRequest(email: email, socialId: idTokenString) { result in
            print(result)
        }
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        showError(error)
    }

    private func showError(_ error: Error) {
        print("Sign in with Apple errored: \(error)")
        Alerts.showInfo(
            title: NSLocalizedString("Failed to Sign in with Apple", comment: ""),
            message: error.localizedDescription
        )
    }
}
