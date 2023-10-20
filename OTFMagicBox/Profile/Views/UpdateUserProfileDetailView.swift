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
import SwiftUI
import OTFCareKitStore
import OTFCloudClientAPI
import OTFUtilities

struct UpdateUserProfileDetailView: View {
    let backgroudColor: UIColor
    let textColor: UIColor
    let cellBackgroundColor: UIColor
    let headerColor: UIColor
    let buttonColor: UIColor
    let borderColor: UIColor
    let sepratorColor: UIColor
    let genderValues = GenderType.allCases
    @StateObject private var viewModel = UpdateUserViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    private var selectedDate: Binding<Date> {
        Binding<Date>(
            get: { self.birthday},
            set : {
                self.birthday = $0
                self.setDateString()
            })
    }
    
    @State private(set) var user: OCKPatient
    @State var firstName: String
    @State var lastName:String
    @State var dob: String
    @State private var image: UIImage?
    @State var profileImageData = Data()
    @State var isHideLoader: Bool = true
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State var birthday: Date
    @State var gender: GenderType
    
    
    init(user: OCKPatient, backgroudColor: UIColor, textColor: UIColor, cellBackgroundColor: UIColor, headerColor: UIColor, buttonColor: UIColor, borderColor: UIColor, sepratorColor: UIColor) {
        _user = State(initialValue: user)
        _firstName = State(initialValue: user.name.givenName ?? "")
        _lastName = State(initialValue: user.name.familyName ?? "")
        _dob = State(initialValue: user.birthday?.toString ?? "")
        self.backgroudColor = backgroudColor
        self.buttonColor = buttonColor
        self.borderColor = borderColor
        self.textColor = textColor
        self.cellBackgroundColor = cellBackgroundColor
        self.headerColor = headerColor
        self.sepratorColor = sepratorColor
        
        self._birthday = State(initialValue: user.birthday ?? Date())
        self._gender = State(initialValue: user.sex?.genderType ?? .other)
        
        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: YmlReader().appTheme?.textColor.color ?? UIColor.black]
    }
    
    var body: some View {
        NavigationView {
            Form {
                VStack {
                    IconView(image: $image,  hashFileKey: user.attachments?.Profile?.hashFileKey ?? "", fileName: user.attachments?.Profile?.attachmentID ?? "", viewModel: viewModel)
                        .frame(width: Metrics.PROFILE_IMAGE_WIDTH, height: Metrics.PROFILE_IMAGE_HEIGHT )
                    Text(name)
                        .font(.title.weight(.bold))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .accessibilityElement(children: .ignore)
                
                Section {
                    HStack {
                        Text(firstNameTitle)
                            .foregroundColor(.otfTextColor)
                            .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                            .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                            .accessibilityHidden(true)
                        TextField(firstNameTitle, text: $firstName)
                            .style(.textField)
                            .foregroundColor(.otfTextColor)
                            .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                            .accessibilityLabel("First Name")
                    }
                    HStack {
                        Text(ModuleAppYmlReader().profileData?.lastName ?? Constants.CustomiseStrings.lastName)
                            .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                            .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                            .foregroundColor(.otfTextColor)
                            .accessibilityHidden(true)
                        TextField(lastNameTitle, text: $lastName)
                            .style(.textField)
                            .foregroundColor(.otfTextColor)
                            .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                            .accessibilityLabel("Last Name")
                    }
                } header: {
                    Text(infoHeader)
                        .font(YmlReader().appTheme?.headerTitleFont.appFont ?? Font.system(size: 17.0))
                        .fontWeight(YmlReader().appTheme?.headerTitleWeight.fontWeight)
                        .foregroundColor(.otfHeaderColor)
                        .textCase(nil)
                }
                
                Section {
                    Picker(Constants.CustomiseStrings.selectGender, selection: $gender) {
                        ForEach(GenderType.allCases, id: \.self) {
                            Text($0.rawValue)
                                .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                                .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                        }
                        .accessibilityLabel("Edit the gender set on your profile")
                        .accessibilityInputLabels(["Edit Gender"])
                    }
                    
                    DatePicker("Birthdate", selection: $birthday, displayedComponents: .date)
                        .accessibilityLabel("Edit the birthdate set on your profile")
                        .accessibilityInputLabels(["Edit Birthdate"])
                } header: {
                    Text(otherInfoHeader)
                        .fontWeight(YmlReader().appTheme?.headerTitleWeight.fontWeight)
                        .foregroundColor(.otfHeaderColor)
                        .font(YmlReader().appTheme?.headerTitleFont.appFont ?? Font.system(size: 17.0))
                        .textCase(nil)
                }
                
                Button(action: {
                    updatePatient()
                    if let image = image {
                        isHideLoader = false
                        if let imageData = image.pngData() {
                            let bytesImage = viewModel.swiftSodium.getArrayOfBytesFromData(FileData: imageData as NSData)
                            let hashKeyFile = viewModel.swiftSodium.generateGenericHashWithoutKey(message: bytesImage)
                            let hashKeyFileHex = hashKeyFile.bytesToHex(spacing: "").lowercased()
                            let uuid = UUID().uuidString + ".png"
                            viewModel.uploadFile(data: imageData, fileName: uuid , hashFileKey: hashKeyFileHex)
                            
                        }
                    }
                }, label: {
                    Text(Constants.CustomiseStrings.save)
                        .padding(Metrics.PADDING_BUTTON_LABEL)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.otfButtonColor)
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .overlay(
                            RoundedRectangle(cornerRadius: Metrics.RADIUS_CORNER_BUTTON)
                                .stroke(Color.otfButtonColor, lineWidth: 2)
                        )
                })
                
            }
        }
                        .listRowBackground(Color.otfCellBackground)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarTitle(Text(ModuleAppYmlReader().profileData?.title ?? "Profile"))
                        .overlay(LoaderView(tintColor: .black, scaleSize: 2.0).padding(.bottom,50).hidden(isHideLoader))
            
            .onReceive(NotificationCenter.default.publisher(for: .databaseSuccessfllySynchronized)) { notification in
                viewModel.fetchPatient(userId: user.id)
            }
            .onReceive(viewModel.patientPublisher) { patient in
                patientData(patient: patient)
            }
            .onReceive(viewModel.profileImageData) { data in
                let dataDict:[String: Data] = ["imageData": data]
                NotificationCenter.default.post(name: .imageUploaded, object: dataDict)
                presentationMode.wrappedValue.dismiss()
            }
            
            .onReceive(NotificationCenter.default.publisher(for: .deleteProfile)) { notification in
                if let fileName = user.attachments?.Profile?.attachmentID {
                    isHideLoader = false
                    viewModel.deleteAttachment(attachmentID: fileName)
                    viewModel.deleteFileFromDocument(fileName: fileName)
                }
            }
            .onReceive(viewModel.hideLoader) { value in
                isHideLoader  = true
                NotificationCenter.default.post(name: .imageUploaded, object: nil)
                presentationMode.wrappedValue.dismiss()
            }
            .onAppear {
                if let attachmentID = user.attachments?.Profile?.attachmentID {
                    if profileImageData.retriveFile(fileName: attachmentID) != nil  {} else  {
                        viewModel.downloadFile(attachmentID: attachmentID)
                    }
                }
            }
        }
    
    
    
    func patientData(patient: OCKPatient) {
        self.user = patient
        self.firstName = patient.name.givenName ?? ""
        self.lastName = patient.name.familyName ?? ""
        self.gender = patient.sex?.genderType ?? .other
        self.birthday = patient.birthday ?? Date()
        setDateString()
    }
    
    func updatePatient() {
        // TODO: - Update user's profile here
        var name = PersonNameComponents()
        name.givenName = firstName
        name.familyName = lastName
        user.name = name
        user.birthday = birthday
        user.sex = gender.carekitGender
        viewModel.updatePatient(user: user)
    }
    
    private func setDateString() {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd-yyyy"
            dob = formatter.string(from: self.birthday)
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

struct IconView: View {
    @Binding var image: UIImage?
    @State var hashFileKey : String
    @State var fileName: String
    @State var imageViews = Data()
    @State private var shouldPresentImagePicker = false
    @State private var shouldPresentActionScheet = false
    @State private var sourceType = UIImagePickerController.SourceType.photoLibrary
    @StateObject var viewModel: UpdateUserViewModel
    @State var imageUI : UIImage? = nil
    
    var imageView: Image {
        
        if let image = image {
            return Image(uiImage: image)
        } else if let imageUI = imageUI {
            return Image(uiImage: imageUI)
        } else {
            return Image.avatar
        }
       
    }
    
    var body: some View {
        imageView
            .iconStyle()
            .aspectRatio(contentMode: .fill)
            .onTapGesture { self.shouldPresentActionScheet = true }
            .sheet(isPresented: $shouldPresentImagePicker) {
                SUImagePickerView(sourceType: self.sourceType, image: self.$image, isPresented: self.$shouldPresentImagePicker)
            }
            .onLoad {
                DispatchQueue.main.async {
                    if let retriveImageData = imageViews.retriveFile(fileName: fileName)  {
                        imageUI = viewModel.dataToImageWithoutDecryption(data: retriveImageData, key: hashFileKey)
                    }
                }
            }
            .actionSheet(isPresented: $shouldPresentActionScheet) { () -> ActionSheet in
                ActionSheet(title: Text(Constants.CustomiseStrings.chooseMode)
                    .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                    .fontWeight(YmlReader().appTheme?.textWeight.fontWeight),
                            message: Text(Constants.CustomiseStrings.chooseProfileImage)
                    .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
                    .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0)), buttons: [ActionSheet.Button.default(Text(Constants.CustomiseStrings.camera), action: {
                        self.shouldPresentImagePicker = true
                        self.sourceType = .camera
                    }), ActionSheet.Button.default(Text(Constants.CustomiseStrings.photoLibrary), action: {
                        self.shouldPresentImagePicker = true
                        self.sourceType = .photoLibrary
                    }), ActionSheet.Button.destructive(Text(Constants.CustomiseStrings.deleteProfile), action: {
                        NotificationCenter.default.post(name: .deleteProfile, object: nil)
                    }), ActionSheet.Button.cancel()])
            }
            .accessibilityLabel("Profile image")
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Double tap to update your profile image")
            .accessibilityIgnoresInvertColors(true)
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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
        for byte in self
        {
            hexString.append(String(format:"%02X", byte))
            count = count - 1
            if count > 0
            {
                hexString.append(spacing)
            }
        }
        return hexString
    }
}
