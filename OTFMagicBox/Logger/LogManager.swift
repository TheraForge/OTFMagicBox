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

/// Manages log entries within the application using `OSLogStore`, allowing querying
/// based on date ranges and log levels.
@available(iOS 15.0, *)
class LogManager {
    /// Reference to the `OSLogStore`, which provides access to system logs.
    private let store: OSLogStore?
    
    /// Initializes the `LogManager` and attempts to set up the `OSLogStore` with
    /// a scope limited to the current process identifier.
    ///
    /// - Throws: An error if the `OSLogStore` cannot be initialized.
    init() throws {
        do {
            self.store = try OSLogStore(scope: .currentProcessIdentifier)
        } catch {
            throw error
        }
    }
    
    /// Queries logs within a specified date range and optional log level.
    ///
    /// - Parameters:
    ///   - startDate: The start date from which logs should be queried.
    ///   - endDate: An optional end date up to which logs should be queried.
    ///   - logLevel: An optional log level filter, returning only entries of this level if specified.
    /// - Returns: An array of `OSLogEntryLog` entries that match the specified criteria.
    /// - Throws: `LogManagerError.invalidLogStore` if `OSLogStore` is unavailable, or
    ///           `LogManagerError.invalidBundleIdentifier` if the bundle identifier cannot be retrieved.
    func queryAsync(
        startDate: Date,
        endDate: Date? = nil,
        logLevel: OSLogEntryLog.Level? = nil
    ) async throws -> [OSLogEntryLog] {
        guard let store else {
            throw LogManagerError.invalidLogStore
        }
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            throw LogManagerError.invalidBundleIdentifier
        }
        
        let position = store.position(date: startDate)
        let predicate = NSPredicate(format: "subsystem == %@", "\(bundleIdentifier)")
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                do {
                    let logs = try store.getEntries(at: position, matching: predicate)
                        .compactMap { $0 as? OSLogEntryLog }
                        .filter { logEntry in
                            if let logLevel, logEntry.level != logLevel {
                                return false
                            }
                            if let endDate, logEntry.date > endDate {
                                return false
                            }
                            return true
                        }
                    continuation.resume(returning: logs)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

enum LogManagerError: Error {
    /// Throw when the log store is invalid
    case invalidLogStore
    /// Throw when the bundle identifier is invalid
    case invalidBundleIdentifier
}

extension LogManagerError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidLogStore:
            return "The OSLogStore is invalid."
        case .invalidBundleIdentifier:
            return "The bundle identifier is invalid."
        }
    }
}
