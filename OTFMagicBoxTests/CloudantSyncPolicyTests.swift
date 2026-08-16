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
import OTFCloudClientAPI
import OTFCareKitStore
import OTFCDTDatastore
import OTFCloudantStore
@testable import OTFMagicBox

@Suite("Cloudant sync policy")
struct CloudantSyncPolicyTests {
    @Test("Sync Policy Uses Push Then Pull When Local Changes Are Pending")
    func syncPolicyUsesPushThenPullWhenLocalChangesArePending() {
        #expect(CloudantSyncPolicy.explicitSyncOrder(hasPendingLocalChanges: true) == .pushThenPull)
        #expect(CloudantSyncPolicy.foregroundSyncOrder(
                hasPendingLocalChanges: true,
                lastSuccessfulSyncDate: Date(),
                maxAge: 45
            ) == .pushThenPull)
        #expect(CloudantSyncPolicy.remoteChangeFeedSyncOrder(hasPendingLocalChanges: true) == .pushThenPull)
    }

    @Test("Sync Policy Uses Pull Only For Remote Only Work")
    func syncPolicyUsesPullOnlyForRemoteOnlyWork() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        #expect(CloudantSyncPolicy.foregroundSyncOrder(
                hasPendingLocalChanges: false,
                lastSuccessfulSyncDate: nil,
                now: now,
                maxAge: 45
            ) == .pullOnly)
        #expect(CloudantSyncPolicy.foregroundSyncOrder(
                hasPendingLocalChanges: false,
                lastSuccessfulSyncDate: now.addingTimeInterval(-60),
                now: now,
                maxAge: 45
            ) == .pullOnly)
        #expect(CloudantSyncPolicy.remoteChangeFeedSyncOrder(hasPendingLocalChanges: false) == .pullOnly)
    }

    @Test("Sync Policy Skips Fresh Foreground Sync Without Local Changes")
    func syncPolicySkipsFreshForegroundSyncWithoutLocalChanges() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        #expect((CloudantSyncPolicy.foregroundSyncOrder(
                hasPendingLocalChanges: false,
                lastSuccessfulSyncDate: now.addingTimeInterval(-10),
                now: now,
                maxAge: 45
            )) == nil)
    }

    @Test("Deletion Sweep Startup Fails When Required Tracker Cannot Start")
    func deletionSweepStartupFailsWhenRequiredTrackerCannotStart() {
        #expect(deletionSweepStartupDecision(
                syncOrder: .pushThenPull,
                trackerStartupResult: .failed("missing datastore")
            ) == .finishWithError("missing datastore"))
        #expect(deletionSweepStartupDecision(
                syncOrder: .pullThenPush,
                trackerStartupResult: .failed("missing datastore")
            ) == .finishWithError("missing datastore"))
    }

    @Test("Deletion Sweep Startup Continues For Pull Only When Tracker Cannot Start")
    func deletionSweepStartupContinuesForPullOnlyWhenTrackerCannotStart() {
        #expect(deletionSweepStartupDecision(
                syncOrder: .pullOnly,
                trackerStartupResult: .failed("missing datastore")
            ) == .continueWithoutSweep)
    }

    @Test("Deletion Sweep Startup Runs Sweep When Required Tracker Starts")
    func deletionSweepStartupRunsSweepWhenRequiredTrackerStarts() {
        #expect(deletionSweepStartupDecision(
                syncOrder: .pushThenPull,
                trackerStartupResult: .started
            ) == .runSweep)
    }

    @Test("Explicit sync without local changes pulls before pushing")
    func explicitSyncWithoutLocalChangesPullsBeforePushing() {
        #expect(CloudantSyncPolicy.explicitSyncOrder(hasPendingLocalChanges: false) == .pullThenPush)
    }

    @Test("Maintenance summary reports changed content only when metadata changed")
    func maintenanceSummaryReportsChangedContentOnlyWhenMetadataChanged() {
        #expect(!SyncMaintenanceSummary.empty.changedScheduleContent)
        #expect(SyncMaintenanceSummary(backfilledTaskDateMetadata: 1, prunedOutcomeDocuments: 0).changedScheduleContent)
        #expect(SyncMaintenanceSummary(backfilledTaskDateMetadata: 0, prunedOutcomeDocuments: 1).changedScheduleContent)
    }
}
