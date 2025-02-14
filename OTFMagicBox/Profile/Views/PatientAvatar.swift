/*
 Copyright (c) 2024, Hippocrates Technologies Sagl. All rights reserved.

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

import SwiftUI
import OTFUtilities
import OTFCareKitStore

struct PatientAvatar: View {
    var image: Image?
    var givenName: String
    var familyName: String
    
    var initials: String {
        let givenNameInitial = givenName.prefix(1).uppercased()
        let familyNameInitial = familyName.prefix(1).uppercased()
        
        switch (givenNameInitial.isEmpty, familyNameInitial.isEmpty) {
        case (true, true): return ""
        case (false, true): return givenNameInitial
        case (true, false): return familyNameInitial
        case (false, false): return givenNameInitial + familyNameInitial
        }
    }
    
    var placeholder: some View {
        Circle()
            .fill(
                LinearGradient(colors: [
                    Color(red: 0.85, green: 0.85, blue: 0.85),
                    Color(red: 0.74, green: 0.74, blue: 0.74)
                ],
                               startPoint: .top,
                               endPoint: .bottom)
            )
            .overlay (
                Text(initials)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
            )
    }
    
    var body: some View {
        if let image {
            image
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        } else {
            placeholder
        }
    }
}

#Preview("With Image") {
    if #available(iOS 15.0, *) {
        AsyncImage(url: URL(string: "https://thispersondoesnotexist.com/")) { image in
            PatientAvatar(image: image, givenName: "Brandon", familyName: "Ashwin")
        } placeholder: {
            Text("Loading")
        }
    }
}

#Preview("Placeholder") {
    PatientAvatar(image: nil, givenName: "Brandon", familyName: "Ashwin")
}
