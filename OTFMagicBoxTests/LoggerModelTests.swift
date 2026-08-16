/*
 Copyright (c) 2026, Hippocrates Technologies Sagl. All rights reserved.
 */

import OSLog
import Testing
@testable import OTFMagicBox

@Suite("Logger models")
struct LoggerModelTests {
    @Test("Log levels expose stable order identifiers and display names")
    func logLevelsExposeStableOrderIdentifiersAndDisplayNames() {
        #expect(OSLogEntryLog.Level.allCases == [.undefined, .debug, .info, .notice, .error, .fault])
        #expect(OSLogEntryLog.Level.allCases.map(\.id) == OSLogEntryLog.Level.allCases.map(\.rawValue))
        #expect(OSLogEntryLog.Level.allCases.map(\.displayName) == [
            "All",
            "Debug",
            "Info",
            "Notice",
            "Error",
            "Fault"
        ])
    }

    @Test("Sample log factory entries expose deterministic categories and levels")
    func sampleLogFactoryEntriesExposeDeterministicCategoriesAndLevels() {
        let info = SampleLog.info
        let error = SampleLog.error

        #expect(info.level == .info)
        #expect(info.category == "Network")
        #expect(info.subsystem == "com.example.app")
        #expect(info.composedMessage == "Successfully connected to API endpoint")

        #expect(error.level == .error)
        #expect(error.category == "Network")
        #expect(error.subsystem == "com.example.app")
        #expect(error.composedMessage == "Failed to connect to API endpoint")
    }
}
