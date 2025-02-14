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

import Foundation
import SwiftUI
import OTFCareKitStore
import OTFCloudClientAPI
import OTFUtilities

struct UpdateUserProfileDetailView: View {
    let genderValues = GenderType.allCases
    @ObservedObject var viewModel: UpdateUserViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.editMode) private var editMode
    
    @State private var user: OCKPatient
    @State private var tempUser: OCKPatient
    @State private var image: UIImage?
    @State private var tempImage: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    @State private var shouldPresentImagePicker = false
    @State private var shouldPresentActionSheet = false
    @State private var sourceType = UIImagePickerController.SourceType.photoLibrary
    @State private var shouldPresentContactPicker = false
    
    var avatarImage: Image? {
        let selectedImage = editMode?.wrappedValue.isEditing == true ? tempImage : image
        if let selectedImage {
            return Image(uiImage: selectedImage)
        } else {
            return nil
        }
    }
    
    init(user: OCKPatient, viewModel: UpdateUserViewModel) {
        self._user = State(initialValue: user)
        self._tempUser = State(initialValue: user)
        self.viewModel = viewModel
        self._image = State(initialValue: viewModel.profileImage)
        self._tempImage = State(initialValue: viewModel.profileImage)
    }
    
    var body: some View {
        ZStack {
            Form {
                avatarSection
                
                Section(header: Text(Constants.CustomiseStrings.personalInformation)) {
                    HStack {
                        Text(Constants.CustomiseStrings.firstName)
                        Spacer()
                        if editMode?.wrappedValue.isEditing == true {
                            TextField(Constants.CustomiseStrings.firstName, text: Binding(
                                get: { tempUser.name.givenName ?? "" },
                                set: { tempUser.name.givenName = $0 }
                            ))
                            .multilineTextAlignment(.trailing)
                            .textContentType(.givenName)
                        } else {
                            Text(user.name.givenName ?? "")
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Constants.CustomiseStrings.firstName)
                    .accessibilityValue(user.name.givenName ?? "")
                    
                    HStack {
                        Text(Constants.CustomiseStrings.lastName)
                        Spacer()
                        if editMode?.wrappedValue.isEditing == true {
                            TextField(Constants.CustomiseStrings.lastName, text: Binding(
                                get: { tempUser.name.familyName ?? "" },
                                set: { tempUser.name.familyName = $0 }
                            ))
                            .textContentType(.familyName)
                            .multilineTextAlignment(.trailing)
                        } else {
                            Text(user.name.familyName ?? "")
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Constants.CustomiseStrings.lastName)
                    .accessibilityValue(user.name.familyName ?? "")
                    
                    birthdaySection
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(Constants.CustomiseStrings.birthdate)
                    
                    genderSection
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(Constants.CustomiseStrings.gender)
                        .accessibilityValue(user.sex?.genderType.rawValue ?? Constants.CustomiseStrings.notSet)
                }
            }
            .navigationTitle(Constants.CustomiseStrings.profile)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if editMode?.wrappedValue.isEditing == true {
                        Button(Constants.CustomiseStrings.cancel) {
                            editMode?.animation().wrappedValue = .inactive
                            tempUser = user
                            tempImage = image
                        }
                        .disabled(isLoading)
                    } else {
                        EmptyView()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .disabled(isLoading)
                }
            }
            .disabled(isLoading)
            .sheet(isPresented: $shouldPresentImagePicker) {
                SUImagePickerView(sourceType: self.sourceType, image: self.$tempImage, isPresented: self.$shouldPresentImagePicker)
            }
            .sheet(isPresented: $shouldPresentContactPicker) {
                ContactPicker(image: self.$tempImage, isPresented: self.$shouldPresentContactPicker)
            }
            .actionSheet(isPresented: $shouldPresentActionSheet) { () -> ActionSheet in
                ActionSheet(title: Text(Constants.CustomiseStrings.chooseMode)
                    .font(Font.otfAppFont)
                    .fontWeight(Font.otfFontWeight),
                            message: Text(Constants.CustomiseStrings.chooseProfileImage)
                    .fontWeight(Font.otfFontWeight)
                    .font(Font.otfAppFont),
                            buttons: [
                                ActionSheet.Button.default(Text(Constants.CustomiseStrings.camera), action: {
                                    self.shouldPresentImagePicker = true
                                    self.sourceType = .camera
                                }),
                                ActionSheet.Button.default(Text(Constants.CustomiseStrings.photoLibrary), action: {
                                    self.shouldPresentImagePicker = true
                                    self.sourceType = .photoLibrary
                                }),
                                ActionSheet.Button.default(Text(Constants.CustomiseStrings.fromContact), action: {
                                    self.shouldPresentContactPicker = true
                                }),
                                ActionSheet.Button.destructive(Text(Constants.CustomiseStrings.deleteProfile), action: {
                                    self.tempImage = nil
                                }),
                                ActionSheet.Button.cancel(Text(Constants.CustomiseStrings.cancel))
                            ])
            }
            .onChange(of: editMode?.wrappedValue) { newValue in
                if newValue?.isEditing == false {
                    if user != tempUser || tempImage != image {
                        saveChanges()
                    }
                } else if newValue?.isEditing == true {
                    tempUser = user
                    tempImage = image
                }
            }
            .onReceive(viewModel.$isLoading) { loading in
                isLoading = loading
            }
            .onReceive(viewModel.profileUpdateComplete) { _ in
                self.editMode?.animation().wrappedValue = .inactive
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text(Constants.CustomiseStrings.error)
                        .font(Font.otfAppFont)
                        .fontWeight(Font.otfFontWeight),
                    message: Text(errorMessage ?? Constants.CustomiseStrings.error),
                    dismissButton: .default(Text(Constants.CustomiseStrings.okay))
                )
            }
            
            if isLoading {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2)
                    )
                    .accessibilityLabel(Constants.CustomiseStrings.loading)
            }
        }
        .navigationBarBackButtonHidden(editMode?.wrappedValue.isEditing == true || isLoading)
    }
    
    var avatarSection: some View {
        Section {
            VStack {
                PatientAvatar(image: avatarImage,
                              givenName: tempUser.name.givenName ?? "",
                              familyName: tempUser.name.familyName ?? "")
                .frame(width: Metrics.PROFILE_IMAGE_WIDTH, height: Metrics.PROFILE_IMAGE_HEIGHT)
                .clipShape(Circle()) // Ensures a round image
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                if editMode?.wrappedValue.isEditing == true {
                    Button(action: {
                        self.shouldPresentActionSheet = true
                    }) {
                        Text(Constants.CustomiseStrings.editPhoto)
                            .foregroundColor(.blue)
                            .padding()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Constants.CustomiseStrings.profilePicture)
            .accessibilityAddTraits(editMode?.wrappedValue.isEditing == true ? .isButton : [])
            .accessibilityHint(editMode?.wrappedValue.isEditing == true ? Constants.CustomiseStrings.editProfilePictureHint : "")
            .background(Color.clear)
        }
        .listRowBackground(Color.clear)
    }
    
    @ViewBuilder
    var birthdaySection: some View {
        if editMode?.wrappedValue.isEditing == true {
            DatePicker(Constants.CustomiseStrings.birthdate, selection: Binding(
                get: { tempUser.birthday ?? Date() },
                set: { tempUser.birthday = $0 }
            ), displayedComponents: .date)
        } else {
            HStack {
                Text(Constants.CustomiseStrings.birthdate)
                Spacer()
                if #available(iOS 15.0, *) {
                    Text(user.birthday?.formatted(date: .long, time: .omitted) ?? Constants.CustomiseStrings.notSet)
                } else {
                    Text(user.birthday?.description ?? Constants.CustomiseStrings.notSet)
                }
            }
        }
    }
    
    @ViewBuilder
    var genderSection: some View {
        if editMode?.wrappedValue.isEditing == true {
            Picker(Constants.CustomiseStrings.selectGender, selection: Binding(
                get: { tempUser.sex?.genderType ?? .other },
                set: { tempUser.sex = $0.carekitGender }
            )) {
                ForEach(GenderType.allCases, id: \.self) { gender in
                    Text(gender.rawValue).tag(gender)
                }
            }
            .pickerStyle(.wheel)
        } else {
            HStack {
                Text(Constants.CustomiseStrings.gender)
                Spacer()
                Text(user.sex?.genderType.rawValue ?? Constants.CustomiseStrings.notSet)
            }
        }
    }
    
    private func saveChanges() {
        user = tempUser
        image = tempImage
        
        viewModel.updatePatientWithImage(user: user, newImage: tempImage)
        
        // Wait for complete update
        viewModel.profileUpdateComplete
            .first()
            .sink { _ in
                self.isLoading = false
            }
    }
}


// MARK: - Labels
extension UpdateUserProfileDetailView {
    var name: String {
        guard let givenName = user.name.givenName,
              let familyName = user.name.familyName else {
            return ""
        }
        return "\(givenName) \(familyName)"
    }
    
    var infoHeader: String {
        ModuleAppYmlReader().profileData?.profileInfoHeader ?? Constants.CustomiseStrings.basicInformation
    }
    
    var firstNameTitle: String {
        ModuleAppYmlReader().profileData?.firstName ?? Constants.CustomiseStrings.firstName
    }
    
    var lastNameTitle: String {
        ModuleAppYmlReader().profileData?.lastName ?? Constants.CustomiseStrings.lastName
    }
    
    var otherInfoHeader: String {
        ModuleAppYmlReader().profileData?.otherInfo ?? Constants.CustomiseStrings.otherInformation
    }
}

extension GenderType {
    var carekitGender: OCKBiologicalSex {
        switch self {
        case .male:
            return .male
            
        case .female:
            return .female
            
        case .other:
            return .other("")
        }
    }
}

extension OCKBiologicalSex {
    var genderType: GenderType {
        switch self {
        case .male:
            return .male
            
        case .female:
            return .female
            
        default:
            return .other
        }
    }
}

struct SUImagePickerView: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    
    func makeCoordinator() -> ImagePickerViewCoordinator {
        return ImagePickerViewCoordinator(image: $image, isPresented: $isPresented)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let pickerController = UIImagePickerController()
        pickerController.sourceType = sourceType
        pickerController.delegate = context.coordinator
        return pickerController
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Nothing to update here
    }
}

class ImagePickerViewCoordinator: NSObject, UINavigationControllerDelegate,
                                  UIImagePickerControllerDelegate {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    
    init(image: Binding<UIImage?>, isPresented: Binding<Bool>) {
        self._image = image
        self._isPresented = isPresented
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.image = image
        }
        self.isPresented = false
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.isPresented = false
    }
}

extension Array where Element == UInt8 {
    func bytesToHex(spacing: String) -> String {
        var hexString: String = ""
        var count = self.count
        for byte in self {
            hexString.append(String(format: "%02X", byte))
            count -= 1
            if !isEmpty {
                hexString.append(spacing)
            }
        }
        return hexString
    }
}

#Preview {
    UpdateUserProfileDetailView(user: .init(id: "1", givenName: "Branson", familyName: "Ashwin"), viewModel: .init())
}
