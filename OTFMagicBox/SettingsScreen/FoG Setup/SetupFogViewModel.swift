//
//  SetupFogViewModel.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 9/10/22.
//

import Foundation
import Combine

class SetupFogViewModel: ObservableObject {
    @Published var alertToPresent: AlertModel?
    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    
    func askForReset() {
        let confirmAction = AlertAction(title: "Confirm", handler: {
            self.alertToPresent = nil
            self.reset()
            self.viewDismissalModePublisher.send(true)
        })
        let denyAction = AlertAction(title: "Deny", style: .destructive, handler: {
            self.alertToPresent = nil
        })
        alertToPresent = AlertModel(title: "Reset to Defaults", message: "Are you sure you want to reset stop FoG list to defaults", actions: [confirmAction, denyAction])
    }
    
    func reset() {
        print("Reset fog to defaults")
    }
}
