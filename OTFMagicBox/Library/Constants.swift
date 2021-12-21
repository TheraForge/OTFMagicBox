/*
Copyright (c) 2021, Hippocrates Technologies S.r.l.. All rights reserved.

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
    static let app = "otfmagicbox.theraforge"
    static let patientEmail = "patientEmail"
    static let userType = "patient"
    static let patientFirstName = "patientFirstName"
    static let patientLastName = "patientLastName"
    
    static let yamlFile = "AppSysParameters.yml"
    
    static let prefConfirmedLogin = "PREF_CONFIRMED_LOGIN"
    static let prefFirstRunWasMarked = "PREF_FIRST_RUN"
    static let prefUserEmail = "PREF_USER_EMAIL"
    
    static let prefCareKitDataInitDate = "PREF_DATA_INIT_DATE"
    static let prefHealthRecordsLastUploaded = "PREF_HEALTH_LAST_UPLOAD"
    
    static let notificationUserLogin = "NOTIFICATION_USER_LOGIN"
    
    static let dataBucketUserDetails = "userDetails"
    static let dataBucketSurveys = "surveys"
    static let dataBucketHealthKit = "healthKit"
    static let dataBucketStorage = "storage"
    
    static let onboardingDidComplete = "didCompleteOnboarding"
    
    // String representation of Bool to compare with yaml file's booleans
    static let `true` = "true"
    static let `false` = "false"
    
    struct UserDefaults {
        //Patient data
        static let patientEmail = "patientEmail"
        static let patientFirstName = "patientFirstName"
        static let patientLastName = "patientLastName"
        static let patientGender = "female"
        static let patientDob = "10/10/1990"
        
        
        //Consent
        static let ConsentDocumentSignature = "ConsentDocumentParticipantSignature"
        static let ConsentDocumentURL = "consentFormURL"
        
        //Misc
        static let FirstRun = "firstRun"
        static let FirstLogin = "firstLogin"
        static let CompletedMarketingSurvey = "completedMarketingSurvey"
        static let HKDataShare = "healthKitShare"
        static let HKStartDate = "healthKitDate"
        
        //Session
        static let DeviceToken = "deviceToken"
        static let UserId = "userId"
        static let ValidSession = "validSession"
        
        // Surveys
        static let MedicalSurvey = "medicalSurvey"
        static let SF12Survey = "sf12Survey"
        static let SurgicalSurvey = "surgicalSurvey"
        static let PhysicalSurvey = "physicalSurvey"
        
        // Watch
        static let WatchReceivedFiles = "watch.receivedFiles"
        static let WatchTransferFailedFiles = "watch.failedFiles"
    }
    
    struct Notification {
        static let MessageArrivedNotification = "MessageArrivedNotification"
        static let DidRegisterNotifications = "DidRegisterUserNotificationSettings"
        static let DidRegisterNotificationsWithToken = "didRegisterForRemoteNotificationsWithDeviceToken"
        
        static let WalkTestRequest = "WalkTestRequest"
        static let APIUserErrorNotification = "APIUserErrorNotification"
        static let DataSyncRequest = "DataSyncRequest"
        static let DatabaseSynchronizedSuccessfully = "DatabaseSynchronizedSuccessfully"
        
        //Reset tab navigation badges
        static let BadgeReset = "BadgeReset"
        
        //Session
        static let SessionExpired = "UserSessionExpired"
        static let SessionReset = "SessionReset"
        
        //Watch
        static let SessionWatchReachabilityDidChange = "SessionWatchReachabilityDidChange"
        static let SessionWatchStateDidChange = "sessionWatchStateDidChange"
    }
    
    struct YamlDefaults {
        static let APIKey = "SS9sfzWq4aWVIk0XdX4He3c2Fi9XPdcIBL0fPil7qd5t2CsWleIVvxs0tQpYTk6BeYM8zLmPCPCGZjfQ2SEt2hOFnDIv0TL0HnzT0tcp2332hgQ9BmlVaeOLWt8UrfpkJr3hf6iPngpAWaeV5Eiuljry7SxdDEhHIII6OMjSkMdykenx9fIok54HLQ8gt9pOYiyvN2gL"
        static let FileName = "AppSysParameters.yml"
        static let LoginStepTitle = "Default: login step title"
        static let LoginStepText = "Default: login step text"
        static let StudyTitle = "Default: study Title"
        static let TeamName = "Default: team name"
        static let TeamEmail = "Default: team email"
        static let TeamPhone = "Default: team phone"
        static let TeamCopyright = "Default: copyright"
        static let TeamWebsite = "Default: team website"
        static let ReviewConsentStepText = "Default: review consent step text"
        static let ReasonForConsentText = "Default: reason for consent step text"
        static let ConsentFileName = "Default: consent file name"
        static let PasscodeText = "Default: passcode text"
        static let PasscodeOnReturnText = "Default: passcode on return text"
        static let CompletionStepTitle = "Default: completion step title"
        static let CompletionStepText = "Default: completion step text"
        static let FailedLoginText = "Default: failed login text"
        static let FailedLoginTitle = "Default: failed login title"
        static let HealthPermissionsTitle = "Default: health permissions title"
        static let HealthPermissionsText = "Default: health permissions text"
        static let ConsentTitle = "Default: consent title"
        static let HealthRecordsPermissionsTitle = "Default: health records permissions title"
        static let HealthRecordsPermissionsText = "Default: health records permissions text"
        static let ConsentSummary = "Default: consent summary"
        static let ConsentContent = "Default: consent content"
        static let ConsentShow = true
    }
    
    struct Images {
        static let ConsentCustomImg = "consent_custom_img1"
    }
    
    struct Passcode {
        static let lengthSix = "6"
        static let lengthFour = "4"
    }
  
    struct Identifier {
        static let ConsentStep = "VisualConsentStep"
        static let ConsentReviewStep = "ConsentReviewStep"
        static let HealthKitDataStep = "Healthkit"
        static let HealthRecordsStep = "HealthRecords"
        static let PasscodeStep = "PasscodeStep"
        static let CompletionStep = "CompletionStep"
        static let StudyOnboardingTask = "StudyOnboardingTask"
    }
    
    struct Registration {
        static let Identifier = "RegistrationStep"
        static let Title = "Registration"
        static let Text = "Sign up for this study."
        static let PasscodeInvalidMessage = "Password must be at least 10 characters in length."
    }
    
    struct Login {
        static let Identifier = "LoginStep"
        static let Title = "Login"
        static let Text = "Log into this study."
    }
    
    struct API {
        static let developmentUrl = "https://theraforge.org/api"
        static let dbProxyURL = API.developmentUrl + "/v1/db/"
        static let dbProxyEmail = "test_patient1@test.com"
        static let dbProxyPassword = "123123123"
    }
    
}
