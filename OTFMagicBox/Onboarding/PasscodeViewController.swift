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
            
            Alerts.showInfo(title: Constants.CustomiseStrings.wrongPasscode, message: Constants.CustomiseStrings.okay)
        }
    }
    
}


import UIKit

public class Alerts {
    
    public class func showInfo(_ vc: UIViewController? = .none, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: Constants.CustomiseStrings.okay, style: .default, handler: nil)
        alert.addAction(cancelAction)
        
        vc?.present(alert, animated: true, completion: nil)
    }
    
}
