/*
 Copyright (c) 2025, Hippocrates Technologies Sagl. All rights reserved.

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

enum Constants {

    enum App {
        static let bundleIdentifier = "org.theraforge.magicbox.ios"
    }

    enum Generic {
        static let `true` = "true"
        static let `false` = "false"
    }

    enum Network {
        static let openAPIURL = "https://stg.theraforge.org/api"
        static let dbProxyURL = openAPIURL + "/v1/db/"
        static let gatewayServicesURL = openAPIURL + "/v1/"
    }

    enum Auth {
        static let signInButtons = "SignInButtons"
        static let loginExistingStep = "LoginExistingStep"
        static let registrationStep = "RegistrationStep"
        static let loginStep = "LoginStep"
        static let passcodeStep = "PasscodeStep"
        static let consentReviewStep = "ConsentReviewStep"
        static let completionStep = "CompletionStep"
        static let studyAuthTask = "StudyAuthTask"
        static let healthKitDataStep = "Healthkit"
        static let healthRecordsStep = "HealthRecords"
        static let visualConsentStep = "VisualConsentStep"
    }

    enum Storage {
        static let kOnboardingCompleted = "storage.onboarding.completed"
        static let kHealthKitDataShare = "storage.healthkit.data.share"
        static let kCareKitDataInitDate = "storage.carekit.data.init.date"
        static let kHealthRecordsLastUploaded = "storage.health.records.last.uploaded"
        static let kConsentDocumentViewed = "storage.consent.document.viewed"
        static let kLastProfileAttachmentID = "storage.last.profile.attachment.id"
        static let kLastProfileHashFileKey = "storage.last.profile.hash.file.key"
        static let kConsentDocumentURL = "storage.consent.document.url"
        static let kHealthKitStartDate = "storage.healthkit.start.date"
        static let kPendingOfflineChanges = "storage.pending.offline.changes"
        static let kHealthSensorsMockEnabled = "storage.healthsensors.mock.enabled"
        static let kHealthSensorsMockSeed = "storage.healthsensors.mock.seed"
        static let kDashboardSelectedMetrics = "storage.dashboard.selected_metrics"
        static let kHealthKitRequestedMetrics = "storage.healthkit.requested_metrics"
    }
    
    enum Notification {
        static let kOnboardingCompleted = "notification.onboarding.completed"
        static let kDataSyncRequest = "notification.data.sync.request"
        static let kDatabaseSynchronized = "notification.database.synchronized"
        static let kImageDownloaded = "notification.image.downloaded"
        static let kDeleteUserAccount = "notification.delete.user.account"
        static let kHealthSensorsLiveHeartRate = "notification.healthsensors.live.heart.rate"
    }
}
