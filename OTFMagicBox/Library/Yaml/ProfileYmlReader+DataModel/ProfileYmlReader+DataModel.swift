//
//  ProfileYmlReader+DataModel.swift
//  OTFMagicBox
//
//  Created by Arsalan Raza on 26/04/2022.
//

import Foundation
import UIKit
import SwiftUI
import Yams

public class ProfileYmlReader {
    
    /// Yaml file name.
    private let fileName = Constants.YamlDefaults.ProfileFileName
    
    private var profileDataModel : ProfileDataModel?
    
    init() {
        let fileUrlString = Bundle.main.path(forResource: fileName, ofType: nil)!
        let fileUrl = URL(fileURLWithPath: fileUrlString)
        do {
            if let dataSet = try? Data(contentsOf: fileUrl) {
                guard let data = try? YAMLDecoder().decode([String: ProfileDataModel].self, from: dataSet) else {
                    OTFLog("Yaml decode error")
                    return
                }
                if data["DataModel"] != nil {
                    profileDataModel = data["DataModel"]
                }
            }
        }
    }
    
    var profileData: ProfileModel? {
        guard let langStr = Locale.current.languageCode else { fatalError("language not found") }
        
        switch langStr {
        case "fr":
            return profileDataModel?.fr
        default:
            return profileDataModel?.en
        }
    }
    
    var backgroundColor: UIColor {
        guard let langStr = Locale.current.languageCode else { fatalError("language not found") }
        
        switch langStr {
        case "fr":
            return profileDataModel?.fr.backgroundColor.color ?? UIColor.black
        default:
            return profileDataModel?.en.backgroundColor.color ?? UIColor.black
        }
    }
    
}



struct ProfileModel: Codable{
    let title: String
    let profileImage: String
    let help: String
    let resetPasswordText: String
    let reportProblemText: String
    let supportText: String
    let consentText: String
    let WithdrawStudyText: String
    let profileInfoHeader: String
    let firstName: String
    let lastName: String
    let reportProblemHeader: String
    let otherInfo: String
    let oldPassword: String
    let newPassword: String
    let resetPassword: String
    let backgroundColor: String
}


struct ProfileDataModel: Codable{
    let en: ProfileModel
    let fr: ProfileModel
}
