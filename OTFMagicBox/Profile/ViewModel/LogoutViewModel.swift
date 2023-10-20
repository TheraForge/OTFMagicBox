//
//  LogoutViewModel.swift
//  OTFMagicBox
//
//  Created by Arsalan Raza on 09/09/2022.
//

import Foundation
import OTFCloudClientAPI
import OTFUtilities
import Combine

final class LogoutViewModel: ObservableObject {
    
    //    MARK: - PROPERTY
    
    @Published var showingAlert = false
    @Published var showingOptions = false
    
    private var disposables = Set<AnyCancellable>()
    
//  MARK:  signout request
    func signout() {
        OTFTheraforgeNetwork.shared.signOut()
            .receive(on: DispatchQueue.main)
            .sink { res in
                switch res {
                case .failure(let error):
                    self.showingAlert = true
                    OTFError("error in signout request -> %{public}s.", error.error.message)
                default: break
                }
            } receiveValue: { data in
                OTFLog("data retrieved -> %{public}s.", data.message)
            }
            .store(in: &disposables)
    }
}

