//
//  Extension+Alert.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 9/10/22.
//

import SwiftUI

extension Alert {
    public init(alertModel: AlertModel) {
        switch alertModel.actions.count {
        case 1:
            let action = alertModel.actions.first!
            self.init(
                title: Text(alertModel.title),
                message: Text(alertModel.message),
                dismissButton: action.alertButton()
            )
        case 2:
            let firstAction = alertModel.actions.first!
            let secondAction = alertModel.actions.last!
            self.init(
                title: Text(alertModel.title),
                message: Text(alertModel.message),
                primaryButton: firstAction.alertButton(),
                secondaryButton: secondAction.alertButton()
            )
        default:
            self.init(
                title: Text(alertModel.title),
                message: Text(alertModel.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

extension AlertAction {
  func alertButton() -> Alert.Button {
    switch style {
    case .`default`:
      return Alert.Button.default(Text(title)) { [weak self] in self?.handler() }
    case .cancel:
      return Alert.Button.cancel(Text(title)) { [weak self] in self?.handler() }
    case .destructive:
      return Alert.Button.destructive(Text(title)) { [weak self] in self?.handler() }
    }
  }
}
