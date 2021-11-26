//
//  Extention+Notification.swift
//  OTFMagicBox
//
//  Created by Admin on 26/11/2021.
//

import Foundation

extension NSNotification.Name {
    static let onboardingDidComplete = NSNotification.Name(Constants.onboardingDidComplete)
    static let dataSyncRequest = NSNotification.Name(rawValue: Constants.Notification.DataSyncRequest)
}
