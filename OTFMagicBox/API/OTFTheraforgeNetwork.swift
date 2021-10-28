//
//  OTFTheraforgeNetwork.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 21/09/21.
//

import Foundation
import OTFCloudClientAPI

class OTFTheraforgeNetwork {
    
    static let shared = OTFTheraforgeNetwork()
    
    var otfNetworkService: NetworkingLayer!
    
    var user: OTFCloudClientAPI.Response.User?
        
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
        otfNetworkService = NetworkingLayer.shared
    }
    
    // Login request
    public func loginRequest(email: String, password: String, completionHandler:  @escaping (Result<Response.Login, ForgeError>) -> Void) {
        otfNetworkService.login(request: OTFCloudClientAPI.Request.Login(email: email,
                                                                         password: password)) { (result) in
            switch result {
            case .success(let response):
                    self.user = response.data
                    UserDefaults.standard.set(response.data.email, forKey: Constants.patientEmail)
            case .failure(_):
                    break
            }
            completionHandler(result)
        }
       
    }
    
    // Registration request
    // swiftlint:disable all
    public func signUpRequest(first_name: String, last_name: String, type: String, email: String,
                              password: String, dob: String, gender: String,
                              completionHandler:  @escaping (Result<Response.Login, ForgeError>) -> Void) {
        otfNetworkService.signup(request: OTFCloudClientAPI.Request.SignUp(email: email, password: password, first_name: first_name,
                                                last_name: last_name, type: .patient, dob: dob, gender: gender, phoneNo: "")) { (result) in
       
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
    public func signOut() {
        otfNetworkService.signOut(completionHandler: { (result) in
            switch result {
            case .success(_):
                    DispatchQueue.main.async {
                        self.user = nil
                        NotificationCenter.default.post(name: NSNotification.Name(Constants.onboardingDidComplete), object: false)
                    }
            case .failure(_):
                    break
            }
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

}
