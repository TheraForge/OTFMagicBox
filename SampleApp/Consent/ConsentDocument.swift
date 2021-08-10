//
//  ConsentDocument.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 14.05.21.
//

import ResearchKit

/**
  The Consent document of the patient.
 */
class ConsentDocument: ORKConsentDocument {
    
    // MARK: Properties
    
    override init() {
        super.init()
        
        let consentTitle = "Consent Title"
        
        title = NSLocalizedString(consentTitle, comment: "")
        sections = []
        
        let sectionTypes: [ORKConsentSectionType] = [
            .overview,
            .dataGathering,
            .privacy,
            .dataUse,
            .studySurvey,
            .studyTasks,
            .withdrawing,
        ]
        
        let consentForm = ["Overview": ["Title": "Overview", "Summary": "Hi there", "Content": "Hi there"],
                           "": ["Title": "Data Gathering", "Summary": "Set of public and private data collection systems, including health surveys, administrative enrollment and billing records and medical records used by various entities including hospitals, CHCs, physicians and health plans", "Content": "Set of public and private data collection systems, including health surveys, administrative enrollment and billing records and medical records used by various entities including hospitals, CHCs, physicians and health plans."],
                           "Privacy": ["Title": "Privacy", "Summary": "Patient data provides an invaluable resource for improving operational and clinical efficiencies.", "Content": "Patient data provides an invaluable resource for improving operational and clinical efficiencies."],
                           "DataUse": ["Title": "Data Use", "Summary": "Healthcare data collection is used to make digital analysis faster and more accurate.", "Content": "Healthcare data collection is used to make digital analysis faster and more accurate."],
                           "StudySurvey": ["Title": "Study Survey", "Summary": "Your survey answers, health information and a copy of this document will be locked in our files.", "Content": "Your survey answers, health information and a copy of this document will be locked in our files."],
                           "StudyTasks": ["Title": "Study Tasks", "Summary": "Various tasks depending on your health issues.", "Content": "Various tasks depending on your health issues."],
                           "Withdrawing": ["Title": "Withdrawing", "Summary": "You can any time withdraw the study.", "Content": "You can any time withdraw the study."]]
        
        for type in sectionTypes {
            let section = ORKConsentSection(type: type)
            
            if let consentSection = consentForm[type.description] {
                
                let errorMessage = "We didn't find a consent form for your project."
            
                section.title = NSLocalizedString(consentSection["Title"] ?? ":(", comment: "")
                section.summary = NSLocalizedString(consentSection["Summary"] ?? errorMessage, comment: "")
                section.content = NSLocalizedString(consentSection["Content"] ?? errorMessage, comment: "")
                
                sections?.append(section)
            }
        }
        
        let signature = ORKConsentSignature(forPersonWithTitle: nil, dateFormatString: nil, identifier: Constants.UserDefaults.ConsentDocumentSignature)
        signature.title = title
        signaturePageTitle = title
        addSignature(signature)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ORKConsentSectionType: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .overview:
            return "Overview"
            
        case .privacy:
            return "Privacy"
            
        case .dataUse:
            return "DataUse"
            
        case .timeCommitment:
            return "TimeCommitment"
            
        case .studySurvey:
            return "StudySurvey"
            
        case .studyTasks:
            return "StudyTasks"
            
        case .withdrawing:
            return "Withdrawing"
            
        case .custom:
            return "Custom"
            
        case .onlyInDocument:
            return "OnlyInDocument"
        case .dataGathering:
            return ""
        @unknown default:
            return ""
        }
    }
}

