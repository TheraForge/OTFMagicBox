/*
 Copyright (c) 2024, Hippocrates Technologies Sagl. All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

 3. Neither the name of the copyright holder(s) nor the names of any contributor(s) may
 be used to endorse or promote products derived from this software without specific
 prior written permission. No license is granted to the trademarks of the copyright
 holders even if such marks are included in this software.

 4. Commercial redistribution in any form requires an explicit license agreement with the
 copyright holder(s). Please contact support@hippocratestech.com for further information
 regarding licensing.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE.
 */

import Foundation
import OSLog
import SwiftUI


@available(iOS 15.0, *)
enum LogLevel: String, CaseIterable, Identifiable {
    case all = "All"
    case info = "Info"
    case debug = "Debug"
    case error = "Error"
    case fault = "Fault"
    case notice = "Notice"
    case undefined = "Undefined"

    var id: String { self.rawValue }

    var osLogLevel: OSLogEntryLog.Level? {
        switch self {
        case .all:
            return nil
        case .info:
            return .info
        case .debug:
            return .debug
        case .error:
            return .error
        case .fault:
            return .fault
        case .notice:
            return .notice
        case .undefined:
            return .undefined
        }
    }

    var color: Color {
        switch self {
        case .info:
            return .blue
        case .debug:
            return .green
        case .error:
            return .red
        case .fault:
            return .purple
        case .notice:
            return .orange
        case .all, .undefined:
            return .gray
        }
    }

    init(from osLogLevel: OSLogEntryLog.Level) {
        switch osLogLevel {
        case .info:
            self = .info
        case .debug:
            self = .debug
        case .error:
            self = .error
        case .fault:
            self = .fault
        case .notice:
            self = .notice
        case .undefined:
            self = .undefined
        @unknown default:
            self = .undefined
        }
    }
}
