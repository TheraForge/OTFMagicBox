//
//  StopFogView.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/19/22.
//

import SwiftUI

struct StopFogView: View {
    @State var isPlaying: Bool = false
    @State var isEditing: Bool = false
    @State var editMode: EditMode = .inactive
    @ObservedObject var viewModel: StopFogViewModel
    var body: some View {
        VStack(spacing: 0) {
            MainHeaderView(title: "STOP FOG")
                .frame(height: 90)
            VStack(spacing: 0) {
                HStack {
                    if !$isEditing.wrappedValue {
                        Button {
                            isPlaying.toggle()
                        } label: {
                            Text("Play")
                                .bold(size: 32)
                                .foregroundColor(Colors.primary)
                        }
                        .padding(.leading, 32)
                    }
                    Spacer()
                    Button{
                        isEditing.toggle()
                        editMode = isEditing ? .active : .inactive
                    }  label: {
                        Text($isEditing.wrappedValue ? "Done" : "Edit")
                            .semiBold(size: 24)
                            .foregroundColor(Colors.primary)
                    }
                    .padding(.trailing, 32)
                }
            }.frame(height: 72)
                .background(UIColor.systemGray6.suiColor)
            List() {
                ForEach(viewModel.items) { item in
                StopFogCellItem(item: item, isEditing: $isEditing.wrappedValue, deleteCellAction: viewModel.deleteCellAction)
                }
                .onMove(perform: viewModel.move)
            }
            .environment(\.editMode, $editMode)
            .background(Color.white)
            .listRowInsets(EdgeInsets())
        }
        .background(Color.gray)
        .onAppear {
            UITableView.appearance().separatorColor = .clear
            UITableView.appearance().contentInset.top = -25
        }
        .fullScreenCover(isPresented: $isPlaying, onDismiss: {
            isPlaying = false
        }) {
            StopFogActionView(viewModel: StopFogActionViewModel(actionList: viewModel.items))
        }
        Spacer()
    }
}

struct StopFogView_Previews: PreviewProvider {
    static var previews: some View {
        StopFogView(viewModel: StopFogViewModel())
    }
}
