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
    static let app = "org.theraforge.magicbox.ios"
    static let patientEmail = "patientEmail"
    static let userType = "patient"
    static let patientFirstName = "patientFirstName"
    static let patientLastName = "patientLastName"
    
    static let yamlFile = "AppSysParameters.yml"
    static let moduleAppFileName = "ModuleAppSysParameter.yml"
    
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
    static let isConsentDocumentViewed = "isConsentDocumentViewed"
    
    static let sizeToCropImage = CGSize(width: 1920.0, height: 1500.0)
    
    // String representation of Bool to compare with yaml file's booleans
    static let `true` = "true"
    static let `false` = "false"
    
    static let deleteAccount = "Your account is deleted from one of your device"
    
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
        static let ImageUploadedSuccessfully = "ImageUploadedSuccessfully"
        static let ImageDownloadedSuccessfully = "ImageDownloadedSuccessfully"
        static let deleteUserAccount = "DeleteUserAccount"
        static let deleteProfile = "DeleteProfile"
        static let fetchImage = "FetchImage"
        
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
        static let APIKey = "this_is_a_dummy_key_to_be_replaced_by_a_valid_one"
        static let FileName = "AppSysParameters.yml"
        static let moduleAppFileName = "ModuleAppSysParameter.yml"
        static let LoginStepTitle = "Default: login step title"
        static let LoginStepText = "Default: login step text"
        static let AppTitle = "Default: App Title"
        static let TeamName = "Default: team name"
        static let TeamEmail = "Default: team email"
        static let TeamPhone = "Default: team phone"
        static let TeamCopyright = "Default: copyright"
        static let TeamWebsite = "Default: team website"
        static let ReviewConsentStepText = "Default: review consent step text"
        static let ReasonForConsentText = "Default: reason for consent step text"
        static let ConsentFileName = "Default: consent file name"
        static let LoginOptionsText = "You can sign in to your cloud account with username and password. Alternatively, you can sign in with your Apple ID or with your Gmail address."
        static let LoginOptionsIcon = "cloud"
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
        static let placeholder = "Your placeholder here"
        static let questionText = "Your question goes here."
        static let Questionnaire = "Questionnaire"
        static let newsletter = "Would you like to subscribe to our newsletter?"
        static let learnMoreText = "Learn more text"
        static let learnMoreTitle = "Learn more title"
        static let birthdayText = "When is your birthday?"
        static let favorite = "Which is your favorite apple?"
        static let participantsText = "Please use this space to provide instructions for participants. Please make sure to provide enough information so that users can progress through the survey and complete with ease."
        static let YourQuestion = "Your question goes here"
        static let defaultTitleForRK = "Default Title"
        static let AppTitleSize = "Title"
    }
    
    struct CustomiseStrings {
        static let signUp = "Sign Up"
        static let signinWithApple = "Sign in with Apple"
        static let resetPassword = "Reset Password"
        static let enterPasscode = "Enter your passcode"
        static let enterYourEmailToGetLink = "Enter your email to get a link for password reset."
        static let enterYourEmail = "Enter your email"
        static let passwordResetError = "Password Reset Error!"
        static let enterTheCode = "Please enter the code sent to your email and new password"
        static let passwordUpdated = "Password has been updated"
        static let enterFirstAndLastName = "Enter your first and last name for the signature of the consent form:"
        static let loginToCloud = "Log in to the cloud to store your data."
        static let signIn = "Sign In"
        static let signingIn = "Signing in..."
        static let signingUp = "Signing up..."
        static let loginingIn = "Logging in..."
        static let loginInError = "Login Error!"
        static let error = "Error"
        static let creatingAccount = "Creating account..."
        static let login = "Login"
        static let registration = "Registration"
        static let submit = "Submit"
        static let wrongPasscode = "Wrong passcode entered"
        static let studySignup = "Sign up for this study."
        static let careTeam = "Care Team"
        static let checkUp = "Check Up"
        static let signinWithGoogle = "Sign in with Google"
        static let signinWithEmail = "Sign in with Email and Password"
        static let missingCredentials = "Missing Credentials"
        static let googleClientId = "You have not provided Google Client ID in the YAML file."
        static let signupForSTOPFoG = "Sign up for the STOP FoG app:"
        static let accountRegistration = "Account Registration"
        static let notMeetCriteria = """
Your password does not meet the following criteria: minimum 8 characters with at least 1 Uppercase Alphabet, 1 Lowercase Alphabet, 1 Number and 1 Special Character
"""
        static let welcome = "Welcome"
        static let defaultDescription = "Default: This is the description."
        static let signAppleIdFastWay = "Sign in using your Apple ID is fast and easy, and Apple will not track any of your activities."
        static let enterValidEmail = "Please enter valid email address!"
        static let forgotPassword = "error in forgot password"
        static let splashImage = "Splash Image"
        static let splashIcon = "stethoscope"
        static let signUpWithEmail = "Sign up with email"
        static let signUpWithApple = "Sign up with Apple"
        static let changePasscode = "Change Passcode"
        static let appSupportRequest = "App Support Request"
        static let enterSupportRequest = "Enter your support request here."
        static let logout = "Logout"
        static let areYouSure = "Are you sure?"
        static let cancel = "Cancel"
        static let failedToLogout = "Failed to logout."
        static let okay = "Okay"
        static let oldPassword = "Old Password"
        static let newPassword = "New Password"
        static let basicInformation = "BASIC INFORMATION"
        static let firstName = "First Name"
        static let lastName = "Last Name"
        static let otherInformation = "Other Information"
        static let selectGender = "Select a Gender"
        static let save = "Save"
        static let chooseMode = "Choose mode"
        static let chooseProfileImage = "Please choose your preferred mode to set your profile image"
        static let camera = "Camera"
        static let photoLibrary = "Photo Library"
        static let deleteProfile = "Remove Profile Image"
        static let deleteAccount = "Delete Account"
        static let removeInformation = "Are you sure? This will remove all your information."
        static let faliedToDeleteAccount = "Failed to delete account."
        static let profile = "Profile"
        static let help = "Help"
        static let reportProblem = "Report a Problem"
        static let support = "Support"
        static let consetDocument = "Consent Document"
        static let withdrawFromStudy = "Withdraw from Study"
        static let accountDeleted = "Account Deleted"
        static let email = "Email"
        static let schedule = "Schedule"
        static let noTasks = "No Tasks"
        static let noTasksForThisDate = "No tasks for this date."
        static let setValidApiKey = "Please set a valid API Key to use the app."
        static let apiKeyMissing = "API Key Missing"
        static let intendedDescription = "Tests ability to walk"
        static let instructionStepTitle = "Patient Questionnaire"
        static let instructionStepText = "This information will help your doctors keep track of how you feel and how well you are able to do your usual activities. If you are unsure about how to answer a question, please give the best answer you can and make a written comment beside your answer."
        static let healthScaleTitle = "Question #1"
        static let healthScaleQuestion = "In general, would you say your health is:"
        static let rowTitle1 = "Row Title"
        static let rowTitle2 = "Percent Progress Row"
        static let rowTitle3 = "Row Title"
        static let rowTitle4 = "Count Progress Row"
        static let rowTitle5 = "Instruction Task View"
        static let rowTitle6 = "Grid Task View"
        static let rowTitle7 = "Simple Task View"
        static let rowTitle8 = "Checklist Task View"
        static let rowTitle9 = "Button Log Task View"
        static let progressRowTitle1 = "Physical Activities"
        static let progressRowTitle2 = "Medications Taken"
        static let progressRowTitle3 = "Checkups"
        static let progressRowTitle4 = "Appointments"
        static let checkupListHeader = "OVERALL ADHERENCE"
        static let touchId = "Use Face ID"
        static let faceId = "Use Touch ID"
        static let faceIdAlertMessage = "To use faceID authentication please login with your credientials first."
        static let touchIdAlertMessage = "To use touchID authentication please login with your credientials first"
    }
    
    struct Images {
        static let ConsentCustomImg = "online-agreement1"
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
        static let developmentUrl = "https://stg.theraforge.org/api"
        static let dbProxyURL = API.developmentUrl + "/v1/db/"
    }
    
}
