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
    
    var onBoardingDataModel : OnBoardingScreen?
    
    init() {
        let fileUrlString = Bundle.main.path(forResource: fileName, ofType: nil)!
        let fileUrl = URL(fileURLWithPath: fileUrlString)
        do {
            if let dataSet = try? Data(contentsOf: fileUrl) {
                guard let data = try? YAMLDecoder().decode([String: OnBoardingScreen].self, from: dataSet) else {
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
            guard let langStr = Locale.current.languageCode else { fatalError("language not found") }
            
            switch langStr {
            case "fr":
                return onBoardingDataModel?.fr.onboarding
            default:
                return onBoardingDataModel?.fr.onboarding
            }
        }
    
    var primaryColor: UIColor {
        guard let langStr = Locale.current.languageCode else { fatalError("language not found") }
        
        switch langStr {
        case "fr":
            let valueSet = (onBoardingDataModel?.fr.onboarding ?? [])
            for item in valueSet{
                return item.color.color ?? UIColor.black
            }
        default:
            let valueSet = (onBoardingDataModel?.en.onboarding ?? [])
            for item in valueSet{
                return item.color.color ?? UIColor.black
            }
        }
        return UIColor.black
    }
}


struct Onboarding: Codable, Equatable {
    let image: String
    let icon: String
    let title: String
    let color: String
    let description: String
}

struct OnBoardingScreen: Codable{
    let en: OnBoardingDataModel
    let fr: OnBoardingDataModel
}

struct OnBoardingDataModel: Codable{
    let onboarding: [Onboarding]
//    let designConfig: [DesignConfig]
}
