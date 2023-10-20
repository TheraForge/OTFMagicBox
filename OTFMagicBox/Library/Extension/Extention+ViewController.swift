//
//  Extention+ViewController.swift
//  OTFMagicBox
//
//  Created by Arsalan Raza on 04/10/2022.
//

import UIKit

extension UIViewController {
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func alertWithAction(title: String , message: String, completionYes: @escaping ((UIAlertAction) -> Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default, handler: completionYes)
        alertController.addAction(okayAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}