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
    @State private var healthProfileDraft: HealthProfileDraft
    @State private var isFullAddressExpanded: Bool
    @State private var profileSaveErrorMessage: String?
    @State private var shouldPreserveDraftAfterSaveFailure = false

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
        let healthProfileDraft = HealthProfileDraft(patient: user)
        _healthProfileDraft = State(initialValue: healthProfileDraft)
        _isFullAddressExpanded = State(initialValue: healthProfileDraft.location.hasStructuredAddress)
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

                if hasEnabledHealthProfileSections {
                    healthProfileSections
                }
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
        .alert(model.config.profileSaveErrorTitle.localized, isPresented: isShowingProfileSaveError) {
            Button(model.config.saveErrorDismissTitle.localized, role: .cancel) { }
        } message: {
            Text(profileSaveErrorMessage ?? model.config.profileSaveErrorMessage.localized)
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
                do {
                    try applyHealthProfileDraft()
                } catch HealthProfileDraftValidationError.invalidCountryCode {
                    presentProfileSaveError(model.config.countryCodeValidationMessage.localized)
                    return
                } catch {
                    presentProfileSaveError(model.config.profileSaveErrorMessage.localized)
                    return
                }

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
            } else if shouldPreserveDraftAfterSaveFailure {
                shouldPreserveDraftAfterSaveFailure = false
            } else {
                tempUser = user
                tempImage = image
                resetHealthProfileDraft()
            }
        }
        .onReceive(model.$isLoading) {
            isLoading = $0
        }
        .onReceive(model.patientPublisher) { saved in
            user = saved
            tempUser = saved
        }
        .onReceive(model.profileUpdateFailed) { _ in
            presentProfileSaveError(model.config.profileSaveErrorMessage.localized)
        }
        .onReceive(model.profileUpdateComplete) { _ in
            user = tempUser
            image = tempImage
            resetHealthProfileDraft()
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

    @ViewBuilder
    private var healthProfileSections: some View {
        if editMode?.wrappedValue.isEditing == true {
            healthProfileNoticeSection
            if model.appConfiguration.enableLocation {
                healthProfileLocationSection
            }
            if model.appConfiguration.enableConditions {
                healthProfileConditionsSection
            }
        } else {
            healthProfileSummarySection
        }
    }

    private var hasEnabledHealthProfileSections: Bool {
        model.appConfiguration.enableLocation || model.appConfiguration.enableConditions
    }

    private var healthProfileNoticeSection: some View {
        Section(model.config.healthProfileTitle.localized) {
            Text(model.config.healthProfilePrivacyNotice.localized)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .globalStyle(.textFont)
        .globalStyle(.textFontWeight)
        .globalStyle(.headerProminence)
    }

    @ViewBuilder
    private var healthProfileSummarySection: some View {
        Section(model.config.healthProfileTitle.localized) {
            if model.appConfiguration.enableLocation {
                LabeledContent(
                    model.config.locationLabel.localized,
                    value: user.profileLocation?.bestAvailableSummary ?? model.config.notSetText.localized
                )
            }
            if model.appConfiguration.enableConditions {
                LabeledContent(
                    model.config.conditionsLabel.localized,
                    value: conditionsSummary(for: user)
                )
            }
        }
        .globalStyle(.textFont)
        .globalStyle(.textFontWeight)
        .globalStyle(.headerProminence)
    }

    private var healthProfileLocationSection: some View {
        Section(model.config.locationLabel.localized) {
            LabeledContent {
                TextField(
                    model.config.locationDisplayNamePlaceholder.localized,
                    text: locationTextBinding(\.country)
                )
                .multilineTextAlignment(.trailing)
                .textInputAutocapitalization(.words)
            } label: {
                Text(model.config.locationDisplayNameLabel.localized)
            }

            LabeledContent {
                TextField(
                    model.config.cityPlaceholder.localized,
                    text: locationTextBinding(\.city)
                )
                .multilineTextAlignment(.trailing)
                .textContentType(.addressCity)
                .textInputAutocapitalization(.words)
            } label: {
                Text(model.config.cityLabel.localized)
            }

            DisclosureGroup(model.config.fullAddressTitle.localized, isExpanded: $isFullAddressExpanded) {
                TextField(model.config.addressLine1Label.localized, text: locationTextBinding(\.addressLine1))
                    .textContentType(.streetAddressLine1)
                TextField(model.config.addressLine2Label.localized, text: locationTextBinding(\.addressLine2))
                    .textContentType(.streetAddressLine2)
                TextField(model.config.regionLabel.localized, text: locationTextBinding(\.region))
                    .textContentType(.addressState)
                TextField(model.config.postalCodeLabel.localized, text: locationTextBinding(\.postalCode))
                    .textContentType(.postalCode)
                TextField(
                    model.config.countryCodePlaceholder.localized,
                    text: locationTextBinding(\.countryCode)
                )
                .textContentType(.telephoneNumber)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .accessibilityLabel(model.config.countryCodeLabel.localized)
            }

            Button(model.config.clearLocationTitle.localized, role: .destructive) {
                healthProfileDraft.location = ProfileLocation()
                isFullAddressExpanded = false
            }
        }
        .globalStyle(.textFont)
        .globalStyle(.textFontWeight)
        .globalStyle(.headerProminence)
    }

    private var healthProfileConditionsSection: some View {
        Section(model.config.conditionsLabel.localized) {
            Text(model.config.conditionsSelectionText.localized)
                .foregroundStyle(.secondary)

            ForEach(HealthProfileConditionCatalogue.conditions) { condition in
                conditionSelectionRow(for: condition)
            }

            reportingStatusSelectionRow(
                status: .none,
                label: model.config.conditionsNoneReportedText.localized
            )

            Button(model.config.clearConditionsTitle.localized, role: .destructive) {
                healthProfileDraft.clearConditions()
            }
        }
        .globalStyle(.textFont)
        .globalStyle(.textFontWeight)
        .globalStyle(.headerProminence)
    }

    private var isShowingProfileSaveError: Binding<Bool> {
        Binding(
            get: { profileSaveErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    profileSaveErrorMessage = nil
                }
            }
        )
    }

    private func locationTextBinding(_ keyPath: WritableKeyPath<ProfileLocation, String?>) -> Binding<String> {
        Binding(
            get: { healthProfileDraft.location[keyPath: keyPath] ?? "" },
            set: { healthProfileDraft.location[keyPath: keyPath] = $0 }
        )
    }

    private func conditionSelectionRow(for condition: MedicalCondition) -> some View {
        let isSelected = healthProfileDraft.reportingStatus == .reported &&
            healthProfileDraft.selectedConditions.contains(condition)

        return Button {
            healthProfileDraft.setCondition(condition, isSelected: !isSelected)
        } label: {
            HStack {
                Text(model.config.conditionLabel(for: condition))
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private func reportingStatusSelectionRow(
        status: ConditionsReportingStatus,
        label: String
    ) -> some View {
        let isSelected = healthProfileDraft.reportingStatus == status

        return Button {
            healthProfileDraft.setReportingStatus(status)
        } label: {
            HStack {
                Text(label)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private func conditionsSummary(for patient: OCKPatient) -> String {
        guard let response = patient.conditionsResponse else {
            return model.config.notSetText.localized
        }
        switch response.status {
        case .none:
            return model.config.conditionsNoneReportedText.localized
        case .unknown:
            return model.config.conditionsUnknownText.localized
        case .reported:
            return response.items
                .map { model.config.conditionLabel(for: $0.coding) }
                .joined(separator: ", ")
        }
    }

    private func applyHealthProfileDraft() throws {
        guard hasEnabledHealthProfileSections else { return }
        try healthProfileDraft.apply(
            to: &tempUser,
            applyLocation: model.appConfiguration.enableLocation,
            applyConditions: model.appConfiguration.enableConditions
        )
    }

    private func resetHealthProfileDraft() {
        let draft = HealthProfileDraft(patient: user)
        healthProfileDraft = draft
        isFullAddressExpanded = draft.location.hasStructuredAddress
    }

    private func presentProfileSaveError(_ message: String) {
        shouldPreserveDraftAfterSaveFailure = true
        profileSaveErrorMessage = message
        editMode?.animation().wrappedValue = .active
    }
}

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
