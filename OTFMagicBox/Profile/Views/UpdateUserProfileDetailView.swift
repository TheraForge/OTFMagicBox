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

struct UpdateUserProfileDetailView: View {
    let color = Color(YmlReader().primaryColor)
    let genderValues = GenderType.allCases
    @State var showGenderPicker = false
    @State var showDatePicker = false
    
    @Environment(\.colorScheme) var colorScheme
    
    private var selectedDate: Binding<Date> {
        Binding<Date>(get: { self.date}, set : {
            self.date = $0
            self.setDateString()
        })
    }
    
    @State private(set) var user: OCKPatient
    @State var firstName: String
    @State var lastName:String
    @State var genderSelection: GenderType
    @State var date: Date
    @State var dob: String
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    private func setDateString() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        
        dob = formatter.string(from: self.date)
    }
    
    static let taskDateFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        return formatter
    }()
    
    init(user: OCKPatient) {
        _user = State(initialValue: user)
        _firstName = State(initialValue: user.name.givenName ?? "")
        _lastName = State(initialValue: user.name.familyName ?? "")
        _genderSelection = State(initialValue: user.sex?.genderType ?? .other)
        _dob = State(initialValue: user.birthday?.toString ?? "")
        _date = State(initialValue: user.birthday ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                IconView()
                    .frame(width: 100, height: 100)
                Section(header: Text(ProfileYmlReader().profileData?.profileInfoHeader ?? "BASIC INFORMATION")) {
                    HStack {
                        Text(ProfileYmlReader().profileData?.firstName ?? "First Name")
                        TextField(ProfileYmlReader().profileData?.firstName ?? "First Name", text: $firstName)
                            .style(.textField)
                    }
                    HStack {
                        Text(ProfileYmlReader().profileData?.lastName ?? "Last Name")
                        TextField(ProfileYmlReader().profileData?.lastName ?? "Last Name", text: $lastName)
                            .style(.textField)
                    }
                }
                
                
                Section(header: Text(ProfileYmlReader().profileData?.otherInfo ?? "Other Information")) {
                    Button(action: {
                        self.showGenderPicker.toggle()
                    }) {
                        Text(" \(genderSelection.rawValue)")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .font(.system(size: 20, weight: .regular))
                    }
                    if showGenderPicker {
                        
                        VStack(alignment:.trailing){
                            Picker("Select a gender", selection: $genderSelection) {
                                ForEach(genderValues, id: \.self) {
                                    Text($0.rawValue)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                        }
                    }
                    
                    
                    Button(action: {
                        self.showDatePicker.toggle()
                    }) {
                        Text(" \(dob)")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .font(.system(size: 20, weight: .regular))
                    }
                    if showDatePicker {
                        
                        VStack(alignment:.trailing){
                            DatePicker("", selection: selectedDate, displayedComponents: .date)
                                .datePickerStyle(WheelDatePickerStyle())
                        }
                    }
                    
                }
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                    updatePatient()
                }, label: {
                    Text("Save")
                        .padding(Metrics.PADDING_BUTTON_LABEL)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(self.color)
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .overlay(
                            RoundedRectangle(cornerRadius: Metrics.RADIUS_CORNER_BUTTON)
                                .stroke(self.color, lineWidth: 2)
                        )
                })
                
            }.navigationBarTitle(Text(ProfileYmlReader().profileData?.title ?? "Profile"))
        }
        .onReceive(NotificationCenter.default.publisher(for: .databaseSuccessfllySynchronized)) { notification in
            CareKitManager.shared.cloudantStore?.fetchPatient(withID: user.id, completion: { result in
                if case .success(let patient) = result {
                    self.user = patient
                    self.firstName = patient.name.givenName ?? ""
                    self.lastName = patient.name.familyName ?? ""
                    self.genderSelection = patient.sex?.genderType ?? .other
                    self.date = patient.birthday ?? Date()
                    setDateString()
                }
            })
        }
    }
    
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
    
    func updatePatient() {
        // TODO: - Update user's profile here
        var name = PersonNameComponents()
        name.givenName = firstName
        name.familyName = lastName
        user.name = name
        user.birthday = date
        user.sex = genderSelection.carekitGender
        CareKitManager.shared.cloudantStore?.updatePatient(user)
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
    @State private var image: Image?
    @State private var shouldPresentImagePicker = false
    @State private var shouldPresentActionScheet = false
    @State private var sourceType = UIImagePickerController.SourceType.photoLibrary
    
    var imageView: Image {
        if let userImage = UIImage(named: ProfileYmlReader().profileData?.profileImage ?? "user_profile") {
            return Image(uiImage: userImage)
        }
        return Image.avatar
    }
    
    var body: some View {
        imageView
            .iconStyle()
            .aspectRatio(contentMode: .fill)
            .onTapGesture { self.shouldPresentActionScheet = true }
            .sheet(isPresented: $shouldPresentImagePicker) {
                SUImagePickerView(sourceType: self.sourceType, image: self.$image, isPresented: self.$shouldPresentImagePicker)
            }
            .actionSheet(isPresented: $shouldPresentActionScheet) { () -> ActionSheet in
                ActionSheet(title: Text("Choose mode"), message: Text("Please choose your preferred mode to set your profile image"), buttons: [ActionSheet.Button.default(Text("Camera"), action: {
                    self.shouldPresentImagePicker = true
                    self.sourceType = .camera
                }), ActionSheet.Button.default(Text("Photo Library"), action: {
                    self.shouldPresentImagePicker = true
                    self.sourceType = .photoLibrary
                }), ActionSheet.Button.cancel()])
            }
    }
}


struct SUImagePickerView: UIViewControllerRepresentable {
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Binding var image: Image?
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
    
    @Binding var image: Image?
    @Binding var isPresented: Bool
    
    init(image: Binding<Image?>, isPresented: Binding<Bool>) {
        self._image = image
        self._isPresented = isPresented
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.image = Image(uiImage: image)
        }
        self.isPresented = false
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.isPresented = false
    }
}
