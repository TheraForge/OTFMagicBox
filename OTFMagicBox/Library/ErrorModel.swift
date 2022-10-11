//
//  ErrorModel.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 9/10/22.
//

import Foundation


public enum ErrorModel: LocalizedError, Identifiable {
    public var id: String { errorTitle }
    
    case reset(message: String)
    
    public var errorTitle: String {
        switch self {
        case .reset(_):
            return "Unable to start session"
        default:
            return ""
        }
    }
    
    public var errorText: String {
        switch self {
        case let .reset(message):
            return message
        }
    }
}
