//
//  ConsentDocument.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 14.05.21.
//

import OTFResearchKit

/**
 The Consent document of the patient.
 */
class ConsentDocument: ORKConsentDocument {
    
    // MARK: Properties
    
    override init() {
        super.init()
        
        let consentTitle = YmlReader().consentTitle
        
        title = consentTitle ?? "Consent Title"
        sections = []
        
        let sectionTypes: [ORKConsentSectionType] = [
            .overview,
            .privacy,
            .dataUse,
            .studySurvey
        ]
        
        let consentData = (YmlReader().consent?.data ?? [ConsentDescription(show: "Default: consent title", summary: "Default: consent summary", content: "Default: consent content")])
        
        for (sectionType, consentData) in zip(sectionTypes, consentData) where consentData.show == "yes" {
                let section = ORKConsentSection(type: sectionType)
                section.title = sectionType.description
                section.summary = consentData.summary
                section.content = consentData.content
                sections?.append(section)
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
            return "DataGathering"
            
        @unknown default:
            return ""
        }
    }
}
