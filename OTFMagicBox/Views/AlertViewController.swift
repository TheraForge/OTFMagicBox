//
//  AlertViewController.swift
//  OTFMagicBox
//
//  Created by Admin on 22/11/2021.
//

import SwiftUI
import UIKit

struct AlertViewController: UIViewControllerRepresentable {
    let title: String
    let message: String
    let dismissButtonTitle: String
    let buttonAction: (() -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    typealias UIViewControllerType = UIAlertController
    
    func updateUIViewController(_ uiViewController: UIAlertController, context: Context) {}
    func makeUIViewController(context: Context) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: dismissButtonTitle, style: .default, handler: { _ in
            self.buttonAction?()
        }))
        
        return alertController
    }
}
