//
//  OTFTheraforgeNetwork.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 21/09/21.
//

import Foundation
import OTFCloudClientAPI

typealias AuthType = Request.SocialLogin.AuthType
typealias SocialType = Request.SocialLogin.SocialType

class OTFTheraforgeNetwork {
    
    static let shared = OTFTheraforgeNetwork()
    
    var otfNetworkService: TheraForgeNetwork!
    
    private init() {
        
        configureNetwork()
        
    }
    
    // Configure the API with required URL and API key.
    public func configureNetwork() {
        guard let url = URL(string: Constants.API.developmentUrl) else {
            OTFLog("Error: cannot create URL")
            return
        }
        
        let configurations = NetworkingLayer.Configurations(APIBaseURL: url, apiKey: YmlReader().apiKey)
        TheraForgeNetwork.configureNetwork(configurations)
        otfNetworkService = TheraForgeNetwork.shared
    }
    
    // Login request
    public func loginRequest(email: String, password: String,
                             completionHandler:  @escaping (Result<Response.Login, ForgeError>) -> Void) {
        otfNetworkService.login(request: OTFCloudClientAPI.Request.Login(email: email,
                                                                         password: password)) { (result) in
            switch result {
            default:
                break
            }
            completionHandler(result)
        }
        
    }
    
    public func socialLoginRequest(userType: UserType,
                                   socialType: SocialType,
                                   authType: AuthType,
                                   idToken: String,
                                   completionHandler: @escaping (Result<Response.Login, ForgeError>) -> Void) {
        let socialRequest = OTFCloudClientAPI.Request.SocialLogin(userType: userType,
                                                                  socialType: socialType,
                                                                  authType: authType,
                                                                  identityToken: idToken)
        otfNetworkService.socialLogin(request: socialRequest) { (result) in
            completionHandler(result)
        }
    }
    
    
    // Registration request
    // swiftlint:disable all
    public func signUpRequest(firstName: String, lastName: String, type: String, email: String,
                              password: String, dob: String, gender: String,
                              completionHandler:  @escaping (Result<Response.Login, ForgeError>) -> Void) {
        otfNetworkService.signup(request: OTFCloudClientAPI.Request.SignUp(email: email, password: password, first_name: firstName,
                                                                           last_name: lastName, type: .patient, dob: dob, gender: gender, phoneNo: "")) { (result) in
            
            completionHandler(result)
        }
    }
    
    // Forgot password request
    public func forgotPassword(email: String, completionHandler:  @escaping (Result<Response.ForgotPassword, ForgeError>) -> Void) {
        otfNetworkService.forgotPassword(request: OTFCloudClientAPI.Request.ForgotPassword(email: email), completionHandler: { (result) in
            
            completionHandler(result)
        })
    }
    
    // Reset password request
    public func resetPassword(email: String, code: String, newPassword: String, completionHandler:  @escaping (Result<Response.ChangePassword, ForgeError>) -> Void) {
        otfNetworkService.resetPassword(request: OTFCloudClientAPI.Request.ResetPassword(email: email, code: code,
                                                                                         newPassword: newPassword), completionHandler: { (result) in
                                                                                            
                                                                                            completionHandler(result)
                                                                                         })
    }
    
    // Signout request.
    public func signOut(completionHandler: ((Result<Response.LogOut, ForgeError>) -> Void)?) {
        otfNetworkService.signOut(completionHandler: { (result) in
            if case .success = result {
                DispatchQueue.main.async {
                    UserDefaults.standard.set(false, forKey: Constants.onboardingDidComplete)
                    NotificationCenter.default.post(name: .onboardingDidComplete, object: false)
                    try? CareKitManager.shared.wipe()
                }
            }
            completionHandler?(result)
        })
    }
    
    // Change password request.
    public func changePassword(email: String, oldPassword: String, newPassword: String, completionHandler:  @escaping (Result<Response.ChangePassword, ForgeError>) -> Void) {
        otfNetworkService.changePassword(request: OTFCloudClientAPI.Request.ChangePassword(email: email, password: oldPassword, newPassword: newPassword), completionHandler: { (result) in
            switch result {
            case .success(let response):
                print(response)
            case .failure(let error):
                print(error)
            }
            completionHandler(result)
        })
    }
    
    func refreshToken(_ completionHandler: @escaping (Result<Response.Login, ForgeError>) -> Void) {
        guard let auth = TheraForgeKeychainService.shared.loadAuth() else {
            completionHandler(.failure(.missingCredential))
            return
        }
        print(auth)
        otfNetworkService.refreshToken(completionHandler: completionHandler)
    }
}
