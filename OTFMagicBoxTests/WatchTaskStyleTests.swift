/*
 Copyright (c) 2026, Hippocrates Technologies Sagl. All rights reserved.

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
import Testing
@testable import OTFMagicBox

@Suite("Watch task style")
struct WatchTaskStyleTests {
    @Test("Task group identifier decodes watch view type")
    func taskGroupIdentifierDecodesWatchViewType() throws {
        var task = makeTask(id: "instruction", start: Date(timeIntervalSince1970: 1_800_000_000), end: nil)
        task.groupIdentifier = try groupIdentifier(viewType: .instruction)

        #expect(task.watchViewType == .instruction)
    }

    @Test("Task group identifier falls back to simple for missing or malformed values")
    func taskGroupIdentifierFallsBackToSimpleForMissingOrMalformedValues() {
        var missing = makeTask(id: "missing", start: Date(timeIntervalSince1970: 1_800_000_000), end: nil)
        var malformed = makeTask(id: "malformed", start: Date(timeIntervalSince1970: 1_800_000_000), end: nil)
        var unknown = makeTask(id: "unknown", start: Date(timeIntervalSince1970: 1_800_000_000), end: nil)
        malformed.groupIdentifier = "{"
        unknown.groupIdentifier = #"{"viewType":"Unsupported"}"#

        #expect(missing.watchViewType == .simple)
        #expect(malformed.watchViewType == .simple)
        #expect(unknown.watchViewType == .simple)
    }

    @Test("SwiftUI support matrix remains explicit")
    func swiftUISupportMatrixRemainsExplicit() {
        let supported = Set(WatchTaskStyle.allCases.filter(\.supportsSwiftUI))

        #expect(supported == [.simple, .instruction, .labeledValue, .numericProgress])
        #expect(!WatchTaskStyle.buttonLog.supportsSwiftUI)
        #expect(!WatchTaskStyle.grid.supportsSwiftUI)
        #expect(!WatchTaskStyle.checklist.supportsSwiftUI)
    }
}

private func groupIdentifier(viewType: WatchTaskStyle) throws -> String {
    let data = try JSONEncoder().encode(WatchTaskGroupIdentifierKeys(viewType: viewType))
    return try #require(String(data: data, encoding: .utf8))
}
