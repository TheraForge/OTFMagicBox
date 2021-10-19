//
//  LoginViewcontroller.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 15.05.21.
//

import Foundation
import OTFResearchKit

/**
  The LoginViewController provides the default login view from ResearchKit.
 */

class LoginViewController: ORKLoginStepViewController {
    
    override func goForward() {
        if let emailRes = result?.results?.first as? ORKTextQuestionResult, let email = emailRes.textAnswer,
           let passwordRes = result?.results?[1] as? ORKTextQuestionResult, let pass = passwordRes.textAnswer {
            let alert = UIAlertController(title: nil, message: "Logging in...", preferredStyle: .alert)

            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = UIActivityIndicatorView.Style.medium
            loadingIndicator.startAnimating()
            alert.view.addSubview(loadingIndicator)

            taskViewController?.present(alert, animated: true, completion: nil)
            
            OTFTheraforgeNetwork.shared.loginRequest(email: email, password: pass) { (result) in
                switch result {
                case .failure(let error):
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        alert.dismiss(animated: true) {
                            let alert = UIAlertController(title: "Login Error!", message: "Please check your credentials.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
                            self.taskViewController?.present(alert, animated: true)
                        }
                    }

                case .success:
                    DispatchQueue.main.async {
                        alert.dismiss(animated: true, completion: nil)
                    }
                    super.goForward()
                }
            }
        }
    }
    
    // Forgot password.
    override func forgotPasswordButtonTapped() {
        let alert = UIAlertController(title: "Reset Password", message: "Enter your email to get a link for password reset.", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Enter your email"
        }

        alert.addAction(UIAlertAction(title: "Submit", style: .default) { (_) in
            let email = alert.textFields![0]
            OTFTheraforgeNetwork.shared.forgotPassword(email: email.text ?? "") { results in
                
                switch results {
                case .failure(let error):
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        alert.dismiss(animated: true, completion: nil)
                        let alert = UIAlertController(title: "Password Reset Error!", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        
                        alert.dismiss(animated: true, completion: nil)
                        self.present(alert, animated: true)
                    }

                case .success:
                    DispatchQueue.main.async {
                        self.resetPassword(email: email.text ?? "")
                    }
                }
                
            }
            })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }
    
    // Reset password for the givem email.
    func resetPassword(email: String) {
        let alert = UIAlertController(title: "Reset Password", message: "Please enter the code sent to your email and new password", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Code "
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "New Password "
            textField.isSecureTextEntry = true
            
        }

        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: ({ _ in
            let code = alert.textFields![0]
            let newPassword = alert.textFields![1]
            OTFTheraforgeNetwork.shared.resetPassword(email: email, code: code.text ?? "", newPassword: newPassword.text ?? "", completionHandler: ({ results in
                
                switch results {
                case .failure(let error):
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        alert.dismiss(animated: true, completion: nil)
                        let alert = UIAlertController(title: "Password Reset Error!", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        
                        alert.dismiss(animated: true, completion: nil)
                        self.present(alert, animated: true)
                    }

                case .success:
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Password has been updated", message: "", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        
                        alert.dismiss(animated: true, completion: nil)
                        self.present(alert, animated: true)
                    }
                }
                
            }))
        })))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }

}
