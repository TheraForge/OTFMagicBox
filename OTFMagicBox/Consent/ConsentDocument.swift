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
        
        title = consentTitle ?? Constants.YamlDefaults.ConsentTitle
        sections = []
        
        let sectionTypes: [ORKConsentSectionType] = [
            .overview,
            .dataGathering,
            .privacy,
            .dataUse,
            .timeCommitment,
            .studySurvey,
            .studyTasks,
            .withdrawing,
            .custom
        ]
        
        let consentData = (YmlReader().consent?.data ?? [ConsentDescription(show: Constants.YamlDefaults.ConsentShow ? "true" : "false", summary: Constants.YamlDefaults.ConsentSummary, content: Constants.YamlDefaults.ConsentContent)])
        
        for (sectionType, consentData) in zip(sectionTypes, consentData) where consentData.show == "true" {
            let section = ORKConsentSection(type: sectionType)
           
            if sectionType == .custom {
                section.customImage = UIImage(named: Constants.Images.ConsentCustomImg)
                section.summary = consentData.summary
                section.content = consentData.content
            }
                
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
            return "Welcome"
            
        case .privacy:
            return "Protecting your Data"
            
        case .dataUse:
            return "Data Use"
            
        case .timeCommitment:
            return "Time Commitment"
            
        case .studySurvey:
            return "Surveys"
            
        case .studyTasks:
            return "Study Tasks"
            
        case .withdrawing:
            return "Withdrawing"
            
        case .custom:
            return "Custom consent section"
            
        case .onlyInDocument:
            return "Only In Document"
            
        case .dataGathering:
            return "Data Processing"
            
        @unknown default:
            return ""
        }
    }
}
