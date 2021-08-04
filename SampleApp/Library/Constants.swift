//
//  Constants.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 14.05.21.
//

import Foundation

class Constants {
    
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
    
    struct UserDefaults {
        
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
    
    struct Sync {
        static let completed = "edu.stanford.vasctrac.sync.completed"
        static let eventsCompleted = "edu.stanford.vasctrac.sync.events.completed"
        static let surveysCompleted = "edu.stanford.vasctrac.sync.surveys.completed"
        static let walkTestCompleted = "edu.stanford.vasctrac.sync.walktest.completed"
        static let hkDay = "edu.stanford.vasctrac.sync.hk.day.completed"
        static let hkEverything = "edu.stanford.vasctrac.sync.hk.everything.completed"
    }
    
    
}
