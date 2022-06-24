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

import Foundation
import OTFResearchKit

/**
 The LoginViewController provides the default login view from ResearchKit.
 */

class LoginViewController: ORKLoginStepViewController {
    
    override func goForward() {
        let emailRes = result?.results?.first as? ORKTextQuestionResult
        guard let email = emailRes?.textAnswer else {
            return
        }
        
        let passwordRes = result?.results?[1] as? ORKTextQuestionResult
        guard let pass = passwordRes?.textAnswer else {
            return
        }
        let alert = UIAlertController(title: nil, message: "Logging in...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        
        taskViewController?.present(alert, animated: true, completion: nil)
        
        OTFTheraforgeNetwork.shared.loginRequest(email: email, password: pass) { (result) in
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    print(error.localizedDescription)
                    alert.dismiss(animated: true) {
                        let alert = UIAlertController(title: "Login Error!", message: error.error.message, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
                        self.taskViewController?.present(alert, animated: true)
                    }
                    
                case .success:
                    alert.dismiss(animated: false, completion: {
                        super.goForward()
                    })
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
                        let alert = UIAlertController(title: "Password Reset Error!", message: error.error.message, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        
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
        
        alert.addAction(UIAlertAction(title: "Submit", style: .default) { _ in
            guard let code = alert.textFields![0].text else {
                fatalError("Invalid code")
            }
            guard let newPassword = alert.textFields![1].text else {
                fatalError("Invalid password")
            }
            
            OTFTheraforgeNetwork.shared.resetPassword(email: email,
                                                      code: code,
                                                      newPassword: newPassword) { results in
                
                switch results {
                case .failure(let error):
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        alert.dismiss(animated: true, completion: nil)
                        let alert = UIAlertController(title: "Password Reset Error!", message: error.error.message, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
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
                
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
}
