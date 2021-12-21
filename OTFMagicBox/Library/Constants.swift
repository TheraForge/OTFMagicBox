//
//  Constants.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 14.05.21.
//

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
        static let APIKey = "He3zxB6mkyevlP1KnIzKJk2vEKFgZMMfhuRwdNt7FniTmKrsHIgTx5ngYg0yRYCxHTJ3JTvMf37B60xhHw9ofamtXRHXmJQpexs1uufKkGPpJoLOilmlqvc6vbG8ztvWFKOT98awdW28yj3SraOh4tNT6UcmQdixtQb7Qz7BwfIftN0NybLPuq54uQEKorq33rCewHhu"
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
