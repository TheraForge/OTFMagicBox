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
import OTFTemplateBox
import RawModel

@RawGenerable
struct AuthConfiguration: Codable {
    let version: String

    // Consent
    let consentFileName: String
    let consentReason: OTFStringLocalized
    let consentTitle: OTFStringLocalized
    @NestedRaw let consentSections: [ConsentSectionConfig]

    // Registration...
    let includeDOB: Bool
    let includeGender: Bool
    let registrationTitle: OTFStringLocalized
    let registrationText: OTFStringLocalized
    let registrationSectionHeader: OTFStringLocalized
    let emailPlaceholder: OTFStringLocalized
    let passwordPlaceholder: OTFStringLocalized
    let dateOfBirthPlaceholder: OTFStringLocalized
    let genderPlaceholder: OTFStringLocalized
    let firstNamePlaceholder: OTFStringLocalized
    let lastNamePlaceholder: OTFStringLocalized
    let passwordInvalidMessage: OTFStringLocalized

    // Passcode
    let passcodeEnabled: Bool
    let passcodeType: String
    let passcodePrompt: OTFStringLocalized

    // Sign-in options
    let loginOptionsText: OTFStringLocalized
    let loginOptionsIcon: String

    // Providers
    let showAppleLogin: Bool
    let showGoogleLogin: Bool

    // Buttons & messages
    let signInWithApple: OTFStringLocalized
    let signUpWithApple: OTFStringLocalized
    let signInWithGoogle: OTFStringLocalized
    let signUpWithGoogle: OTFStringLocalized
    let signInWithEmail: OTFStringLocalized
    let signUpWithEmail: OTFStringLocalized
    let signingInMessage: OTFStringLocalized
    let signingUpMessage: OTFStringLocalized
    let creatingAccountMessage: OTFStringLocalized
    let genericErrorTitle: OTFStringLocalized
    let okayActionTitle: OTFStringLocalized
    let cancelActionTitle: OTFStringLocalized
    let openActionTitle: OTFStringLocalized
    let submitActionTitle: OTFStringLocalized
    let loginErrorTitle: OTFStringLocalized
    let signupErrorTitle: OTFStringLocalized
    let googleSignInFailedTitle: OTFStringLocalized
    let emailVerifyConfirmationTitle: OTFStringLocalized
    let emailVerifyMessage: OTFStringLocalized

    // Login form
    let loginTitle: OTFStringLocalized
    let loginText: OTFStringLocalized
    let loginEmailPlaceholder: OTFStringLocalized
    let loginPasswordPlaceholder: OTFStringLocalized
    let loginSectionHeader: OTFStringLocalized

    // Biometric login
    let faceIdButtonTitle: OTFStringLocalized
    let touchIdButtonTitle: OTFStringLocalized
    let faceIdAlertMessage: OTFStringLocalized
    let touchIdAlertMessage: OTFStringLocalized

    // Forgot/Reset password
    let resetPasswordTitle: OTFStringLocalized
    let forgotPasswordTitle: OTFStringLocalized
    let enterYourEmailToGetLink: OTFStringLocalized
    let enterYourEmailPlaceholder: OTFStringLocalized
    let enterTheCodeMessage: OTFStringLocalized
    let newPasswordPlaceholder: OTFStringLocalized
    let enterValidEmailMessage: OTFStringLocalized
    let passwordResetErrorTitle: OTFStringLocalized
    let passwordUpdatedTitle: OTFStringLocalized

    // Doctor portal
    let doctorPortalConfirmTitle: OTFStringLocalized
    let doctorPortalConfirmMessage: OTFStringLocalized
    let doctorPortalUrl: String

    // Health
    let healthPermissionsTitle: OTFStringLocalized
    let healthPermissionsText: OTFStringLocalized
    let healthBackgroundReadFrequency: String
    let healthTypes: [String]

    @NestedRaw let healthRecords: HealthRecordsConfig?

    // Completion
    let completionTitle: OTFStringLocalized
    let completionText: OTFStringLocalized
}

// MARK: - Fallbacks updated for login-time consent

extension AuthConfiguration: OTFVersionedDecodable {
    typealias Raw = RawAuthConfiguration

    static let fallback = AuthConfiguration(
        version: "2.0.0",

        // Consent
        consentFileName: "TheraForgeConsent",
        consentReason: "I agree to the Terms of Use and acknowledge the Privacy Policy.",
        consentTitle: "Terms & Privacy Agreement",
        consentSections: [
            .init(
                type: "overview",
                show: true,
                title: "Before You Continue",
                summary: "To use this app, please review how we handle your data and agree to our terms.",
                content: "By continuing, you confirm you are over the minimum age, agree to the Terms of Use, and acknowledge the Privacy Policy. You can manage your choices in Settings at any time.",
                image: nil
            ),
            .init(
                type: "dataGathering",
                show: true,
                title: "Data We Collect",
                summary: "Account info, app usage, diagnostics, and optional health data.",
                content: "We collect your account details (e.g., email), device identifiers, crash/diagnostic data, and app usage analytics. With your permission, we may read Health data to power app features. We do not record audio or track precise location.",
                image: nil
            ),
            .init(
                type: "privacy",
                show: true,
                title: "Your Privacy & Security",
                summary: "Encryption in transit and at rest; limited access by authorized staffallback.",
                content: "We encrypt data in transit and at rest. Access is restricted to authorized personnel for support and operations. We never sell your personal information.",
                image: nil
            ),
            .init(
                type: "dataUse",
                show: true,
                title: "How We Use Your Data",
                summary: "To provide the service, improve reliability, and meet legal obligations.",
                content: "We use data to deliver core functionality, troubleshoot issues, improve performance, and comply with applicable laws. Aggregated analytics may inform product decisions. Marketing is optional and can be disabled.",
                image: nil
            ),
            .init(
                type: "withdrawing",
                show: true,
                title: "Your Choices",
                summary: "Manage permissions, download or delete data, or close your account.",
                content: "You can revoke permissions in Settings, request data export or deletion, and close your account. Some data may be retained where required by law or for fraud prevention.",
                image: nil
            ),
            .init(
                type: "custom",
                show: true,
                title: "Links & Contact",
                summary: "Read the full Terms and Privacy Policy or contact support.",
                content: "Terms of Use: example.org/terms\nPrivacy Policy: example.org/privacy\nSupport: support@example.org",
                image: "online-agreement"
            )
        ],

        // Registration (unchanged below) …
        includeDOB: true,
        includeGender: true,
        registrationTitle: "Registration",
        registrationText: "Sign up for this app",
        registrationSectionHeader: "New Account",
        emailPlaceholder: "jappleseed@example.com",
        passwordPlaceholder: "Enter password",
        dateOfBirthPlaceholder: "Pick a date",
        genderPlaceholder: "Pick a gender",
        firstNamePlaceholder: "John",
        lastNamePlaceholder: "Appleseed",
        passwordInvalidMessage: "Password must be at least 10 characters in length",

        // Passcode
        passcodeEnabled: false,
        passcodeType: "4",
        passcodePrompt: "Enter your passcode",

        // Sign-in options
        loginOptionsText: "You can sign in to your cloud account with username and password. Alternatively, you can sign in with your Apple ID or with your Gmail address.",
        loginOptionsIcon: "cloud",

        // Providers
        showAppleLogin: true,
        showGoogleLogin: true,

        // Buttons & messages
        signInWithApple: "Sign in with Apple",
        signUpWithApple: "Sign up with Apple",
        signInWithGoogle: "Sign in with Google",
        signUpWithGoogle: "Sign up with Google",
        signInWithEmail: "Sign in with Email and Password",
        signUpWithEmail: "Sign up with Email and Password",
        signingInMessage: "Signing in...",
        signingUpMessage: "Signing up...",
        creatingAccountMessage: "Creating account...",
        genericErrorTitle: "Error",
        okayActionTitle: "Okay",
        cancelActionTitle: "Cancel",
        openActionTitle: "Open",
        submitActionTitle: "Submit",
        loginErrorTitle: "Unable to Login",
        signupErrorTitle: "Unable to Signup",
        googleSignInFailedTitle: "Failed to Sign in with Google",
        emailVerifyConfirmationTitle: "Account Confirmation",
        emailVerifyMessage: "An email of your account confirmation link has been sent to your address.\nCheck your email and approve the request",

        // Login form
        loginTitle: "Login",
        loginText: "Log in to this app",
        loginEmailPlaceholder: "jappleseed@example.com",
        loginPasswordPlaceholder: "Enter password",
        loginSectionHeader: "Credentials",

        // Biometrics
        faceIdButtonTitle: "Use Face ID",
        touchIdButtonTitle: "Touch ID",
        faceIdAlertMessage: "To use face ID authentication please log in with your credientials first",
        touchIdAlertMessage: "To use touchID authentication please login with your credientials first",

        // Forgot/Reset
        resetPasswordTitle: "Reset Password",
        forgotPasswordTitle: "error in forgot password",
        enterYourEmailToGetLink: "Enter your email to get a link for password reset",
        enterYourEmailPlaceholder: "Enter your email",
        enterTheCodeMessage: "Please enter the code sent to your email and new password",
        newPasswordPlaceholder: "New Password",
        enterValidEmailMessage: "Please enter valid email address!",
        passwordResetErrorTitle: "Password Reset Error!",
        passwordUpdatedTitle: "Password has been updated",

        // Doctor portal
        doctorPortalConfirmTitle: "Open Doctor Portal?",
        doctorPortalConfirmMessage: "You are trying to log in with doctor credentials. That is not currently supported by the app. We'll open the portal at %@ to continue. Proceed?",
        doctorPortalUrl: "https://theraforge.org/portal/login",

        // Health
        healthPermissionsTitle: "Permission to read activity data",
        healthPermissionsText: "Use this text to provide an explanation to your app participants about what activity data you intend to read from the Health app and why. This sample will read step count, distance, heart rate, and flights climbed data.",
        healthBackgroundReadFrequency: "immediate",
        healthTypes: ["StepCount", "DistanceWalkingRunning", "FlightsClimbed"],
        
        healthRecords: HealthRecordsConfig(
            permissionsTitle: "Health Records",
            permissionsText: "Allow the app to read your Health Records to display your clinical data and insights."
        ),

        // Completion
        completionTitle: "Welcome aboard",
        completionText: "This step concludes the onboarding and consent process of the TheraForge framework. Next up, you will see main app functionality."
    )

    init(from raw: RawAuthConfiguration) {
        let fallback = Self.fallback

        version = raw.version ?? fallback.version

        // Consent
        consentFileName = raw.consentFileName ?? fallback.consentFileName
        consentReason = raw.consentReason ?? fallback.consentReason
        consentTitle = raw.consentTitle ?? fallback.consentTitle

        let decodedSections = (raw.consentSections ?? []).map { ConsentSectionConfig(from: $0) }
        consentSections = decodedSections.isEmpty ? fallback.consentSections : decodedSections

        // Registration
        includeDOB = raw.includeDOB ?? fallback.includeDOB
        includeGender = raw.includeGender ?? fallback.includeGender
        registrationTitle = raw.registrationTitle ?? fallback.registrationTitle
        registrationText = raw.registrationText ?? fallback.registrationText
        registrationSectionHeader = raw.registrationSectionHeader ?? fallback.registrationSectionHeader
        emailPlaceholder = raw.emailPlaceholder ?? fallback.emailPlaceholder
        passwordPlaceholder = raw.passwordPlaceholder ?? fallback.passwordPlaceholder
        dateOfBirthPlaceholder = raw.dateOfBirthPlaceholder ?? fallback.dateOfBirthPlaceholder
        genderPlaceholder = raw.genderPlaceholder ?? fallback.genderPlaceholder
        firstNamePlaceholder = raw.firstNamePlaceholder ?? fallback.firstNamePlaceholder
        lastNamePlaceholder = raw.lastNamePlaceholder ?? fallback.lastNamePlaceholder
        passwordInvalidMessage = raw.passwordInvalidMessage ?? fallback.passwordInvalidMessage

        // Passcode
        passcodeEnabled = raw.passcodeEnabled ?? fallback.passcodeEnabled
        passcodeType = raw.passcodeType ?? fallback.passcodeType
        passcodePrompt = raw.passcodePrompt ?? fallback.passcodePrompt

        // Sign-in options
        loginOptionsText = raw.loginOptionsText ?? fallback.loginOptionsText
        loginOptionsIcon = raw.loginOptionsIcon ?? fallback.loginOptionsIcon

        // Providers
        showAppleLogin = raw.showAppleLogin ?? fallback.showAppleLogin
        showGoogleLogin = raw.showGoogleLogin ?? fallback.showGoogleLogin

        // Buttons & messages
        signInWithApple = raw.signInWithApple ?? fallback.signInWithApple
        signUpWithApple = raw.signUpWithApple ?? fallback.signUpWithApple
        signInWithGoogle = raw.signInWithGoogle ?? fallback.signInWithGoogle
        signUpWithGoogle = raw.signUpWithGoogle ?? fallback.signUpWithGoogle
        signInWithEmail = raw.signInWithEmail ?? fallback.signInWithEmail
        signUpWithEmail = raw.signUpWithEmail ?? fallback.signUpWithEmail
        signingInMessage = raw.signingInMessage ?? fallback.signingInMessage
        signingUpMessage = raw.signingUpMessage ?? fallback.signingUpMessage
        creatingAccountMessage = raw.creatingAccountMessage ?? fallback.creatingAccountMessage
        genericErrorTitle = raw.genericErrorTitle ?? fallback.genericErrorTitle
        okayActionTitle = raw.okayActionTitle ?? fallback.okayActionTitle
        cancelActionTitle = raw.cancelActionTitle ?? fallback.cancelActionTitle
        openActionTitle = raw.openActionTitle ?? fallback.openActionTitle
        submitActionTitle = raw.submitActionTitle ?? fallback.submitActionTitle
        loginErrorTitle = raw.loginErrorTitle ?? fallback.loginErrorTitle
        signupErrorTitle = raw.signupErrorTitle ?? fallback.signupErrorTitle
        googleSignInFailedTitle = raw.googleSignInFailedTitle ?? fallback.googleSignInFailedTitle
        emailVerifyConfirmationTitle = raw.emailVerifyConfirmationTitle ?? fallback.emailVerifyConfirmationTitle
        emailVerifyMessage = raw.emailVerifyMessage ?? fallback.emailVerifyMessage

        // Login form
        loginTitle = raw.loginTitle ?? fallback.loginTitle
        loginText = raw.loginText ?? fallback.loginText
        loginEmailPlaceholder = raw.loginEmailPlaceholder ?? fallback.loginEmailPlaceholder
        loginPasswordPlaceholder = raw.loginPasswordPlaceholder ?? fallback.loginPasswordPlaceholder
        loginSectionHeader = raw.loginSectionHeader ?? fallback.loginSectionHeader

        // Biometrics
        faceIdButtonTitle = raw.faceIdButtonTitle ?? fallback.faceIdButtonTitle
        touchIdButtonTitle = raw.touchIdButtonTitle ?? fallback.touchIdButtonTitle
        faceIdAlertMessage = raw.faceIdAlertMessage ?? fallback.faceIdAlertMessage
        touchIdAlertMessage = raw.touchIdAlertMessage ?? fallback.touchIdAlertMessage

        // Forgot/Reset
        resetPasswordTitle = raw.resetPasswordTitle ?? fallback.resetPasswordTitle
        forgotPasswordTitle = raw.forgotPasswordTitle ?? fallback.forgotPasswordTitle
        enterYourEmailToGetLink = raw.enterYourEmailToGetLink ?? fallback.enterYourEmailToGetLink
        enterYourEmailPlaceholder = raw.enterYourEmailPlaceholder ?? fallback.enterYourEmailPlaceholder
        enterTheCodeMessage = raw.enterTheCodeMessage ?? fallback.enterTheCodeMessage
        newPasswordPlaceholder = raw.newPasswordPlaceholder ?? fallback.newPasswordPlaceholder
        enterValidEmailMessage = raw.enterValidEmailMessage ?? fallback.enterValidEmailMessage
        passwordResetErrorTitle = raw.passwordResetErrorTitle ?? fallback.passwordResetErrorTitle
        passwordUpdatedTitle = raw.passwordUpdatedTitle ?? fallback.passwordUpdatedTitle

        // Doctor portal
        doctorPortalConfirmTitle = raw.doctorPortalConfirmTitle ?? fallback.doctorPortalConfirmTitle
        doctorPortalConfirmMessage = raw.doctorPortalConfirmMessage ?? fallback.doctorPortalConfirmMessage
        doctorPortalUrl = raw.doctorPortalUrl ?? fallback.doctorPortalUrl

        // Health
        healthPermissionsTitle = raw.healthPermissionsTitle ?? fallback.healthPermissionsTitle
        healthPermissionsText = raw.healthPermissionsText ?? fallback.healthPermissionsText
        healthBackgroundReadFrequency = raw.healthBackgroundReadFrequency ?? fallback.healthBackgroundReadFrequency
        healthTypes = raw.healthTypes ?? fallback.healthTypes

        healthRecords = raw.healthRecords.map { HealthRecordsConfig(from: $0) } ?? fallback.healthRecords

        // Completion
        completionTitle = raw.completionTitle ?? fallback.completionTitle
        completionText = raw.completionText ?? fallback.completionText
    }

    static func migrate(from version: OTFSemanticVersion, raw: RawAuthConfiguration) throws -> AuthConfiguration {
        AuthConfiguration(from: raw)
    }
}
