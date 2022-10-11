//
//  AlertModel.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 9/10/22.
//

import Foundation
import SwiftUI

public struct AlertModel: Identifiable {
    public var id: UUID = UUID()
    public var title: String
    public var message: String
    public var actions: [AlertAction]
}

extension AlertModel{
    public init(error: ErrorModel, actions: [AlertAction]) {
        title = error.errorTitle
        message = error.errorText
        self.actions = actions
    }
    
    public init(title: String, message: String, actions: [AlertAction]) {
        self.title = title
        self.message = message
        self.actions = actions
    }
}
