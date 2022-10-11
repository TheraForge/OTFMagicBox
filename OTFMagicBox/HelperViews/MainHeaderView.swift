//
//  MainHeaderView.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/19/22.
//

import SwiftUI

struct MainHeaderView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var shouldPresentModal: Bool = false
    @State var title: String
    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                Text(title)
                    .bold(size: 34)
                    .foregroundColor(Color.black)
                    .padding(.leading, 32)
                Spacer()
                Button { shouldPresentModal = true } label: {
                    UIImage.loadImage(named: "person.circle")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color.black)
                        .frame(width: 39, height: 39)
                        .scaledToFill()
                }
                .padding(.trailing, 32)
            }.padding(.bottom, 18)
            Divider().frame(height: 1)
        }.background(Color.white)
        .sheet(isPresented: $shouldPresentModal, onDismiss: { shouldPresentModal = false }, content: {
            ProfileUIView()
        })
    }
}

struct MainHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        MainHeaderView(title: "Test Title")
    }
}
