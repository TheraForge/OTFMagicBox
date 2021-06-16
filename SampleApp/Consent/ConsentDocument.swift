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
            // see ORKConsentSectionType.description for CKConfiguration.plist keys
            .overview,
            .privacy,
            .dataUse
        ]
        
        let consentForm = ["Overview": ["Title": "Hi there", "Summary": "summary 1234", "Content": "summary 1234"],
                           "Privacy": ["Title": "Hi there", "Summary": "summary 1234", "Content": "summary 1234"],
                           "DataUse": ["Title": "hello there", "Summary": "summary 1234", "Content": "summary 1234"]]
        
        for type in sectionTypes {
            let section = ORKConsentSection(type: type)
            
            if let consentSection = consentForm[type.description] {
                
                let errorMessage = "We didn't find a consent form for your project. Did you configure the CKConfiguration.plist file already?"
            
                section.title = NSLocalizedString(consentSection["Title"] ?? ":(", comment: "")
                section.summary = NSLocalizedString(consentSection["Summary"] ?? errorMessage, comment: "")
                section.content = NSLocalizedString(consentSection["Content"] ?? errorMessage, comment: "")
                
                sections?.append(section)
            }
        }
        
        let signature = ORKConsentSignature(forPersonWithTitle: nil, dateFormatString: nil, identifier: "ConsentDocumentParticipantSignature")
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

