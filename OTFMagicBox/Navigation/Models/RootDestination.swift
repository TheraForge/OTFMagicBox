/*
 Copyright (c) 2025, Hippocrates Technologies Sagl. All rights reserved.

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

enum RootDestination: String, Hashable, Identifiable, CaseIterable {
    case schedule, contacts, checkup, ui, profile, playground

    var id: Self { self }

    func title(from model: ContentViewModel) -> String {
        switch self {
        case .schedule: model.config.scheduleTitle.localized
        case .contacts: model.config.contactsTitle.localized
        case .checkup: model.config.checkupTitle.localized
        case .ui: model.config.uiTitle.localized
        case .profile: model.config.profileTitle.localized
        case .playground: model.config.playgroundTitle.localized
        }
    }

    func symbol(from model: ContentViewModel) -> String {
        switch self {
        case .schedule: model.config.scheduleSymbol
        case .contacts: model.config.contactsSymbol
        case .checkup: model.config.checkupSymbol
        case .ui: model.config.uiSymbol
        case .profile: model.config.profileSymbol
        case .playground: model.config.playgroundSymbol
        }
    }

    @ViewBuilder
    func content() -> some View {
        switch self {
        case .schedule: ScheduleView()
        case .contacts: ContactsView()
        case .checkup: CheckUpView()
        case .ui: UILabView()
        case .profile: ProfileView()
        case .playground: SnippetPlaygroundView()
        }
    }
}
