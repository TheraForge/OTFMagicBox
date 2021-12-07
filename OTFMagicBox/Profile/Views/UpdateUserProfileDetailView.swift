//
//  UpdateUserProfileDetailView.swift
//  OTFMagicBox
//
//  Created by Spurti Benakatti on 25/10/21.
//

import Foundation
import SwiftUI
import OTFCareKitStore
import OTFCloudClientAPI

struct UpdateUserProfileDetailView: View {
    let color = Color(YmlReader().primaryColor)
    let genderValues = GenderType.allCases
    @State var showGenderPicker = false
    @State var showDatePicker = false
    
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
                Section(header: Text("Basic Information")) {
                    HStack {
                        Text("FirstName")
                        TextField("FirstName", text: $firstName)
                            .style(.textField)
                    }
                    HStack {
                        Text("LastName")
                        TextField("LastName", text: $lastName)
                            .style(.textField)
                    }
                }
                
                
                Section(header: Text("Other Information")) {
                    Button(action: {
                        self.showGenderPicker.toggle()
                    }) {
                        Text(" \(genderSelection.rawValue)")
                            .foregroundColor(.black)
                            .font(.system(size: 20, weight:.regular))
                    }
                    if showGenderPicker {
                        
                        VStack(alignment:.trailing){
                            Button(action:{self.showGenderPicker = false}){
                                Text("Done")
                            }.frame(alignment: .trailing)
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
                            .foregroundColor(.black)
                            .font(.system(size: 20, weight:.regular))
                    }
                    if showDatePicker {
                        
                        VStack(alignment:.trailing){
                            Button(action:{self.showDatePicker = false}){
                                Text("Done")
                            }.frame(alignment: .topTrailing)
                            DatePicker("", selection: selectedDate, displayedComponents: .date)
                                .datePickerStyle(WheelDatePickerStyle())
                        }
                    }
                    
                }
                
                Button(action: {
                    
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
                
            }.navigationBarTitle(Text("Profile"))
        }
        .onReceive(NotificationCenter.default.publisher(for: .databaseSuccessfllySynchronized)) { notification in
            CareKitManager.shared.cloudantStore?.fetchPatient(withID: user.id, completion: { result in
                if case .success(let patient) = result {
                    self.user = patient
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
    @State private var shouldPresentCamera = false
    
    var imageView: Image {
        image ?? Image.avatar
    }
    
    var body: some View {
        imageView
            .iconStyle()
            .aspectRatio(contentMode: .fill)
            .onTapGesture { self.shouldPresentActionScheet = true }
            .sheet(isPresented: $shouldPresentImagePicker) {
                SUImagePickerView(sourceType: self.shouldPresentCamera ? .camera : .photoLibrary, image: self.$image, isPresented: self.$shouldPresentImagePicker)
            }
            .actionSheet(isPresented: $shouldPresentActionScheet) { () -> ActionSheet in
                ActionSheet(title: Text("Choose mode"), message: Text("Please choose your preferred mode to set your profile image"), buttons: [ActionSheet.Button.default(Text("Camera"), action: {
                    self.shouldPresentImagePicker = true
                    self.shouldPresentCamera = true
                }), ActionSheet.Button.default(Text("Photo Library"), action: {
                    self.shouldPresentImagePicker = true
                    self.shouldPresentCamera = false
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
