//
//  OTFLog.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 01/09/21.
//

import Foundation
import os.log

func OTFError(_ message: StaticString, _ args: CVarArg..., category: String = #function) {
    OTFLogger(.error, message, args, category)
}

func OTFLog(_ message: StaticString, _ args: CVarArg..., category: String = #function) {
    OTFLogger(.info, message, args, category)
}

func OTFLogger(_ type: OSLogType, _ message: StaticString, _ args: CVarArg..., category: String = #function) {
    
    let log = OSLog(subsystem: "\(Constants.app).logging", category: category)
    if #available(iOS 12.0, *), #available(watchOSApplicationExtension 5.0, *) {
        os_log(type, log: log, message, args)
    } else {
        os_log(message, log: log, type: type, args)
    }
}

