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

import OTFResearchKit

/**
 The Consent document of the patient.
 */
class ConsentDocument: ORKConsentDocument {
    
    // MARK: Properties
    
    override init() {
        super.init()
        
        let consentTitle = ModuleAppYmlReader().consentTitle
        
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
        
        let consentData = (ModuleAppYmlReader().consent?.data ?? [ConsentDescription(show: Constants.YamlDefaults.ConsentShow ? Constants.true : Constants.false, summary: Constants.YamlDefaults.ConsentSummary, content: Constants.YamlDefaults.ConsentContent, title: Constants.YamlDefaults.defaultTitleForRK, image: Constants.Images.ConsentCustomImg)])
        
        for (sectionType, consentData) in zip(sectionTypes, consentData) where consentData.show == Constants.true {
            let section = ORKConsentSection(type: sectionType)
           
            if sectionType == .custom {
                section.customImage = UIImage(named: consentData.image)?.crop(to: Constants.sizeToCropImage)
                section.title = consentData.title
            } else {
                section.title = consentData.title
            }
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
