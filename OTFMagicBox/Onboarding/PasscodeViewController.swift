//
//  PasscodeViewController.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 08/07/21.
//

import UIKit
import SwiftUI
import OTFResearchKit

struct PasscodeViewController: UIViewControllerRepresentable {
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    } 

    typealias UIViewControllerType = ORKPasscodeViewController
    
    func updateUIViewController(_ uiViewController: ORKPasscodeViewController, context: Context) {}
    func updateUIViewController(_ taskViewController: ORKTaskViewController, context: Context) {}
    func makeUIViewController(context: Context) -> ORKPasscodeViewController {
        
        
            let editPasscodeViewController = ORKPasscodeViewController.passcodeEditingViewController(withText: "", delegate: context.coordinator, passcodeType:.type4Digit)
            
            return editPasscodeViewController
    }

    class Coordinator: NSObject, ORKPasscodeDelegate {
        func passcodeViewControllerDidCancel(_ viewController: UIViewController) {
            
        }
        
        func passcodeViewControllerDidFinish(withSuccess viewController: UIViewController) {
            viewController.dismiss(animated: true, completion: nil)
        }
        
        func passcodeViewControllerDidFailAuthentication(_ viewController: UIViewController) {
            viewController.dismiss(animated: true, completion: nil)
            
            Alerts.showInfo(title: "Wrong passcode entered", message: "Okay")
        }
    }
    
}


import UIKit

public class Alerts {
    
    public class func showInfo(_ vc: UIViewController? = .none, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(cancelAction)
        
        vc?.present(alert, animated: true, completion: nil)
    }
    
}
