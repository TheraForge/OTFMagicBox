//
//  OnBoardingYmlReader+DataModel.swift
//  OTFMagicBox
//
//  Created by Arsalan Raza on 26/04/2022.
//

import Foundation
import UIKit
import SwiftUI
import Yams

public class OnBoardingYmlReader {
    
    /// Yaml file name.
    private let fileName = Constants.YamlDefaults.onboardingFileName
    
    var onBoardingDataModel : OnBoardingDataModel?
    
    init() {
        let fileUrlString = Bundle.main.path(forResource: fileName, ofType: nil)!
        let fileUrl = URL(fileURLWithPath: fileUrlString)
        do {
            if let dataSet = try? Data(contentsOf: fileUrl) {
                guard let data = try? YAMLDecoder().decode([String: OnBoardingDataModel].self, from: dataSet) else {
                    OTFLog("Yaml decode error")
                    return
                }
                if data["DataModel"] != nil {
                    onBoardingDataModel = data["DataModel"]
                }
            }
        }
    }
    
        var onboardingData: [Onboarding]? {
            return onBoardingDataModel?.onboarding
        }
    
    var primaryColor: UIColor {
        let valueSet = (onBoardingDataModel?.designConfig ?? [])
        
        for value in valueSet where value.name == "label" {
            return value.textValue.color ?? UIColor.black
        }
        return .black
    }
}


struct Onboarding: Codable, Equatable {
    let image: String
    let icon: String
    let title: String
    let color: String
    let description: String
}

struct OnBoardingDataModel: Codable{
    let onboarding: [Onboarding]
    let designConfig: [DesignConfig]
}
