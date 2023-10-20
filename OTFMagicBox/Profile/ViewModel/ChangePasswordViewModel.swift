//
//  ChangePasswordViewModel.swift
//  OTFMagicBox
//
//  Created by Arsalan Raza on 12/09/2022.
//

import Foundation
import OTFCloudClientAPI
import OTFUtilities
import Combine


final class ChangePasswordViewModel: ObservableObject {
    
    @Published var showFailureAlert = false
    @Published var errorMessage = String()
    @Published var oldPassword: String = ""
    @Published var newPassword: String = ""
    @Published var email: String
    
    init(email: String) {
        self.email = email
    }
    
    var error: ForgeError?
    var viewDismissModePublisher = PassthroughSubject<Bool, Never>()
    private var disposables = Set<AnyCancellable>()
    private var shouldDismissView = false {
        didSet {
            viewDismissModePublisher.send(shouldDismissView)
        }
    }
    
//    MARK: chnage password request
    func changePassword() {
        OTFTheraforgeNetwork.shared.changePassword(email: email, oldPassword: oldPassword, newPassword: newPassword)
            .receive(on: DispatchQueue.main)
            .sink { response in
                switch response {
                case .failure(let error):
                    OTFError("error in change password request -> %{public}s.", error.error.message)
                    self.errorMessage = error.error.message
                    self.showFailureAlert = true
                default: break
                }
            } receiveValue: { data in
                self.shouldDismissView = true
                OTFLog("error in change password request -> %{public}s.", data.message)
            }
            .store(in: &disposables)
    }
}

