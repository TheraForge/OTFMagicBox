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
import OTFCareKitStore
import PhotosUI
import OTFCloudClientAPI
import OTFTemplateBox

struct UpdateUserProfileDetailView: View {

    @Environment(\.editMode) private var editMode

    @ObservedObject var model: UpdateUserViewModel

    @State private var user: OCKPatient
    @State private var tempUser: OCKPatient
    @State private var image: UIImage?
    @State private var tempImage: UIImage?

    @State private var isLoading = false
    @State private var showPhotoOptions = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showPhotosPicker = false

    init(user: OCKPatient, model: UpdateUserViewModel) {
        self.model = model
        _user = State(initialValue: user)
        _tempUser = State(initialValue: user)
        _image = State(initialValue: model.profileImage)
        _tempImage = State(initialValue: model.profileImage)
    }

    private var avatarImage: Image? {
        let current = (editMode?.wrappedValue.isEditing == true) ? tempImage : image
        return current.map(Image.init(uiImage:))
    }

    var body: some View {
        ZStack {
            Form {
                // Avatar
                Section {
                    VStack(spacing: 8) {
                        PatientAvatar(image: avatarImage, givenName: tempUser.name.givenName ?? "", familyName: tempUser.name.familyName ?? "")
                            .frame(width: 80, height: 80)
                            .clipShape(.circle)
                            .overlay(
                                Circle()
                                    .stroke(lineWidth: 2.0)
                                    .globalStyle(.borderColor)
                                    .opacity(0.3)
                            )

                        if editMode?.wrappedValue.isEditing == true {
                            Button(model.config.editPhotoTitle.localized) {
                                showPhotoOptions = true
                            }.buttonStyle(.borderless)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)

                // Personal Info
                Section(model.config.personalInfoTitle.localized) {
                    Group {
                        HStack {
                            Text(model.config.firstNameLabel.localized)
                            Spacer()
                            if editMode?.wrappedValue.isEditing == true {
                                TextField(model.config.firstNameLabel.localized, text: Binding(
                                    get: { tempUser.name.givenName ?? "" },
                                    set: { tempUser.name.givenName = $0 }
                                ))
                                .multilineTextAlignment(.trailing)
                                .textContentType(.givenName)
                            } else {
                                Text(user.name.givenName ?? "")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack {
                            Text(model.config.lastNameLabel.localized)
                            Spacer()
                            if editMode?.wrappedValue.isEditing == true {
                                TextField(model.config.lastNameLabel.localized, text: Binding(
                                    get: { tempUser.name.familyName ?? "" },
                                    set: { tempUser.name.familyName = $0 }
                                ))
                                .multilineTextAlignment(.trailing)
                                .textContentType(.familyName)
                            } else {
                                Text(user.name.familyName ?? "")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if editMode?.wrappedValue.isEditing == true {
                            DatePicker(model.config.birthdateLabel.localized, selection: Binding(
                                get: { tempUser.birthday ?? Date() },
                                set: { tempUser.birthday = $0 }
                            ), displayedComponents: .date)
                        } else {
                            LabeledContent(model.config.birthdateLabel.localized, value: user.birthday?.formatted(date: .long, time: .omitted) ?? model.config.notSetText.localized)
                        }

                        if editMode?.wrappedValue.isEditing == true {
                            Picker(model.config.genderLabel.localized, selection: Binding(
                                get: { tempUser.sex?.genderType ?? .other },
                                set: { tempUser.sex = $0.carekitGender }
                            )) {
                                ForEach(GenderType.allCases, id: \.self) { gender in
                                    Text(gender.rawValue).tag(gender)
                                }
                            }
                        } else {
                            LabeledContent(model.config.genderLabel.localized, value: user.sex?.genderType.rawValue ?? model.config.notSetText.localized)
                        }
                    }
                    .globalStyle(.textFont)
                    .globalStyle(.textFontWeight)
                }
                .globalStyle(.headerProminence)
            }
            .disabled(isLoading)

            if isLoading {
                Color.black
                    .opacity(0.4)
                    .ignoresSafeArea()
                    .overlay(ProgressView())
            }
        }
        .globalStyle(.navigationTitleDisplayMode)
        .navigationTitle(model.config.navTitle.localized)
        .confirmationDialog(model.config.changePhotoDialogTitle.localized, isPresented: $showPhotoOptions, titleVisibility: .visible) {
            Button(model.config.chooseFromPhotosTitle.localized) {
                showPhotosPicker = true
            }
            if tempImage != nil {
                Button(model.config.removePhotoTitle.localized, role: .destructive) {
                    tempImage = nil
                }
            }
            Button(model.config.cancelTitle.localized, role: .cancel) { }
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self), let ui = UIImage(data: data) {
                    tempImage = ui
                }
            }
        }
        .onChange(of: editMode?.wrappedValue) { mode in
            guard let mode else { return }
            if !mode.isEditing {
                let userChanged  = (user != tempUser)
                let imageChanged = (image != tempImage)

                guard userChanged || imageChanged else {
                    editMode?.animation().wrappedValue = .inactive
                    return
                }

                isLoading = true
                if !userChanged && imageChanged {
                    model.updatePatientImage(newImage: tempImage)
                } else {
                    model.updatePatient(user: tempUser, imageUpdated: imageChanged, newImage: tempImage)
                }
            } else {
                tempUser = user
                tempImage = image
            }
        }
        .onReceive(model.$isLoading) {
            isLoading = $0
        }
        .onReceive(model.patientPublisher) { saved in
            user = saved
            tempUser = saved
        }
        .onReceive(model.profileUpdateComplete) { _ in
            user = tempUser
            image = tempImage
            editMode?.animation().wrappedValue = .inactive
            model.fetchUserFromDB()
        }
        .onReceive(model.$profileImage) { newImage in
            // Sync local state with model when profile image is updated
            image = newImage
            tempImage = newImage
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton().disabled(isLoading)
            }
        }
    }
}

// MARK: - Helpers

extension GenderType {
    var carekitGender: OCKBiologicalSex {
        switch self {
        case .male: return .male
        case .female: return .female
        case .other: return .other("")
        }
    }
}

extension OCKBiologicalSex {
    var genderType: GenderType {
        switch self {
        case .male: return .male
        case .female: return .female
        default: return .other
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        UpdateUserProfileDetailView(user: .init(id: "1", givenName: "Branson", familyName: "Ashwin"), model: .init())
    }
}
